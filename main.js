/**
 * Main visualization script
 * Uses UnifiedLayoutOptimizer for SAT-based positioning
 */

const width = 1000;
const height = 800;

const svg = d3.select('#venn')
    .attr('width', '100%')
    .attr('height', '100%')
    .attr('style', 'max-width: 100%;');

d3.json('data.json').then(data => {
    // Populate career opportunities list
    const jobsList = document.getElementById('jobs-list');
    data.organizations
        .filter(org => org.careers)
        .sort((a, b) => a.name.localeCompare(b.name))
        .forEach(org => {
            const link = document.createElement('a');
            link.href = org.careers;
            link.target = '_blank';
            link.textContent = org.name;
            jobsList.appendChild(link);
        });

    // Create main group for zoom/pan
    const mainGroup = svg.append('g');

    // Set up zoom behavior
    const zoom = d3.zoom()
        .scaleExtent([0.5, 4])
        .on('zoom', (event) => {
            mainGroup.attr('transform', event.transform);
        });

    svg.call(zoom);

    // Run unified layout optimization
    const optimizer = new UnifiedLayoutOptimizer(width, height);
    const layout = optimizer.optimize(data);

    // Draw circles
    mainGroup.selectAll('.circle')
        .data(layout.circles)
        .join('circle')
        .attr('class', 'circle')
        .attr('cx', d => d.x)
        .attr('cy', d => d.y)
        .attr('r', d => d.r)
        .attr('fill', d => d.color)
        .attr('stroke', d => d.color);

    // Draw circle labels
    mainGroup.selectAll('.label')
        .data(layout.circles)
        .join('text')
        .attr('class', 'label')
        .attr('x', d => d.labelX || d.x)
        .attr('y', d => d.labelY || (d.y - d.r - 20))
        .attr('fill', d => d.color)
        .text(d => d.name);

    // Draw organization dots
    const orgGroups = mainGroup.selectAll('.org-link')
        .data(layout.organizations)
        .join('g')
        .attr('class', 'org-link')
        .on('click', (e, d) => window.open(d.url, '_blank'));

    orgGroups.append('circle')
        .attr('class', 'org-circle')
        .attr('cx', d => d.x)
        .attr('cy', d => d.y)
        .attr('r', 5);

    orgGroups.append('text')
        .attr('class', 'org-text')
        .attr('x', d => d.x)
        .attr('y', d => d.y + 20)
        .text(d => d.name);

    // Calculate and set viewBox to fit everything
    const padding = 50;
    let minX = Infinity, maxX = -Infinity;
    let minY = Infinity, maxY = -Infinity;

    // Include circles
    layout.circles.forEach(c => {
        minX = Math.min(minX, c.x - c.r, c.labelX - 100);
        maxX = Math.max(maxX, c.x + c.r, c.labelX + 100);
        minY = Math.min(minY, c.y - c.r, c.labelY - 20);
        maxY = Math.max(maxY, c.y + c.r, c.labelY + 20);
    });

    // Include organizations
    layout.organizations.forEach(org => {
        if (org.x && org.y) {
            minX = Math.min(minX, org.x - 50);
            maxX = Math.max(maxX, org.x + 50);
            minY = Math.min(minY, org.y - 10);
            maxY = Math.max(maxY, org.y + 30);
        }
    });

    const viewBoxWidth = maxX - minX + 2 * padding;
    const viewBoxHeight = maxY - minY + 2 * padding;
    const viewBoxX = minX - padding;
    const viewBoxY = minY - padding;

    svg.attr('viewBox', `${viewBoxX} ${viewBoxY} ${viewBoxWidth} ${viewBoxHeight}`)
        .attr('preserveAspectRatio', 'xMidYMid meet');

    console.log(`ViewBox: ${viewBoxWidth.toFixed(0)} x ${viewBoxHeight.toFixed(0)}`);
});
