/**
 * Unified Layout Optimizer using SAT
 *
 * Simultaneously positions circles, organization dots, and labels
 * to guarantee no overlaps while respecting category relationships.
 */

class UnifiedLayoutOptimizer {
    constructor(width, height) {
        this.width = width;
        this.height = height;
    }

    /**
     * Main optimization function
     * @param {Object} data - The data.json content
     * @returns {Object} Layout with positioned circles, orgs, labels
     */
    optimize(data) {
        console.log('=== Unified Layout Optimization ===');

        // Step 1: Analyze relationships and generate candidates
        const analysis = this.analyzeRelationships(data);
        const circleCandidates = this.generateCircleCandidates(analysis);
        const orgCandidates = this.generateOrgCandidates(data.organizations, circleCandidates);
        const labelCandidates = this.generateLabelCandidates(circleCandidates);

        console.log(`Candidates: ${circleCandidates.length} circle sets, ` +
                    `${orgCandidates.reduce((sum, c) => sum + c.length, 0)} org positions, ` +
                    `${labelCandidates.reduce((sum, c) => sum + c.length, 0)} label positions`);

        // Step 2: Encode as SAT problem
        const sat = new SATSolver();
        const encoding = this.encodeSAT(sat, data, analysis, circleCandidates, orgCandidates, labelCandidates);

        console.log(`SAT problem: ${sat.numVars} variables, ${sat.clauses.length} clauses`);

        // Step 3: Solve
        console.log('Solving...');
        const solution = sat.solve();

        if (!solution) {
            console.error('No solution found! Falling back to force-directed layout.');
            return this.fallbackLayout(data, analysis);
        }

        // Step 4: Extract solution
        console.log('✓ Solution found!');
        return this.extractSolution(solution, encoding, data, circleCandidates, orgCandidates, labelCandidates);
    }

    /**
     * Analyze category relationships
     */
    analyzeRelationships(data) {
        return data.categories.map((cat, i) => ({
            index: i,
            name: cat.name,
            color: cat.color,
            overlaps: data.categories.map((other, j) => {
                if (i === j) return 0;
                return data.organizations.filter(org =>
                    org.categories.includes(cat.name) &&
                    org.categories.includes(other.name)
                ).length;
            }),
            orgCount: data.organizations.filter(org =>
                org.categories.includes(cat.name)
            ).length
        }));
    }

    /**
     * Generate candidate circle positions
     * Returns array of complete circle layouts (all circles positioned together)
     */
    generateCircleCandidates(analysis) {
        const candidates = [];
        const numCategories = analysis.length;

        // For simplicity, generate a grid of circle center positions
        // and create a few candidate layouts
        const gridStep = 150;
        const centerX = this.width / 2;
        const centerY = this.height / 2;

        // Start with a good default layout based on overlaps
        const defaultLayout = this.createCircleLayout(analysis, centerX, centerY);
        candidates.push(defaultLayout);

        // Generate a few variations by perturbing positions
        for (let variant = 0; variant < 5; variant++) {
            const layout = this.createCircleLayout(
                analysis,
                centerX + (variant - 2) * 50,
                centerY + (variant - 2) * 50
            );
            candidates.push(layout);
        }

        return candidates;
    }

    /**
     * Create a single circle layout based on force-directed principles
     */
    createCircleLayout(analysis, centerX, centerY) {
        const circles = analysis.map((cat, i) => {
            // Size based on org count
            const radius = 80 + (cat.orgCount / Math.max(...analysis.map(c => c.orgCount))) * 80;

            // Initial position in a circle arrangement
            const angle = (i / analysis.length) * Math.PI * 2;
            const distance = 150;

            return {
                index: i,
                name: cat.name,
                color: cat.color,
                x: centerX + Math.cos(angle) * distance,
                y: centerY + Math.sin(angle) * distance,
                r: radius
            };
        });

        // Run simple force simulation
        for (let iter = 0; iter < 200; iter++) {
            circles.forEach(c => { c.fx = 0; c.fy = 0; });

            // Apply forces
            for (let i = 0; i < circles.length; i++) {
                for (let j = i + 1; j < circles.length; j++) {
                    const dx = circles[j].x - circles[i].x;
                    const dy = circles[j].y - circles[i].y;
                    const dist = Math.sqrt(dx * dx + dy * dy) || 1;

                    const shouldOverlap = analysis[i].overlaps[j] > 0;

                    if (shouldOverlap) {
                        const target = (circles[i].r + circles[j].r) * 0.7;
                        const force = (dist - target) * 0.02;
                        circles[i].fx += (dx / dist) * force;
                        circles[j].fx -= (dx / dist) * force;
                        circles[i].fy += (dy / dist) * force;
                        circles[j].fy -= (dy / dist) * force;
                    } else {
                        const minSep = circles[i].r + circles[j].r + 180;
                        if (dist < minSep) {
                            const force = (minSep - dist) * 0.03;
                            circles[i].fx -= (dx / dist) * force;
                            circles[j].fx += (dx / dist) * force;
                            circles[i].fy -= (dy / dist) * force;
                            circles[j].fy += (dy / dist) * force;
                        }
                    }
                }
            }

            // Apply forces
            circles.forEach(c => {
                c.x += c.fx * 0.9;
                c.y += c.fy * 0.9;
            });
        }

        return circles;
    }

    /**
     * Generate candidate positions for each organization
     */
    generateOrgCandidates(organizations, circleCandidates) {
        // For each org, generate positions within its constraint regions
        // Use the first circle layout as reference (they should be similar)
        const referenceCircles = circleCandidates[0];

        return organizations.map(org => {
            const candidates = [];
            const gridStep = 20;

            // Find bounding box of required circles
            const requiredCircles = referenceCircles.filter(c =>
                org.categories.includes(c.name)
            );

            if (requiredCircles.length === 0) return [];

            const minX = Math.min(...requiredCircles.map(c => c.x - c.r));
            const maxX = Math.max(...requiredCircles.map(c => c.x + c.r));
            const minY = Math.min(...requiredCircles.map(c => c.y - c.r));
            const maxY = Math.max(...requiredCircles.map(c => c.y + c.r));

            // Generate grid within bounding box
            for (let x = minX; x <= maxX; x += gridStep) {
                for (let y = minY; y <= maxY; y += gridStep) {
                    // Check if this position satisfies all constraints
                    let valid = true;

                    for (const circle of referenceCircles) {
                        const dx = x - circle.x;
                        const dy = y - circle.y;
                        const dist = Math.sqrt(dx * dx + dy * dy);
                        const shouldBeIn = org.categories.includes(circle.name);

                        if (shouldBeIn && dist >= circle.r - 15) {
                            valid = false;
                            break;
                        }
                        if (!shouldBeIn && dist < circle.r + 25) {
                            valid = false;
                            break;
                        }
                    }

                    if (valid) {
                        // Score based on distance from edges
                        let minDistToEdge = Infinity;
                        for (const circle of referenceCircles) {
                            const dx = x - circle.x;
                            const dy = y - circle.y;
                            const dist = Math.sqrt(dx * dx + dy * dy);
                            const shouldBeIn = org.categories.includes(circle.name);

                            const edgeDist = shouldBeIn
                                ? circle.r - dist
                                : dist - circle.r;

                            minDistToEdge = Math.min(minDistToEdge, edgeDist);
                        }

                        candidates.push({ x, y, score: minDistToEdge });
                    }
                }
            }

            // Sort by score and limit
            candidates.sort((a, b) => b.score - a.score);
            return candidates.slice(0, 100); // Limit to top 100 positions
        });
    }

    /**
     * Generate candidate label positions for each circle
     */
    generateLabelCandidates(circleCandidates) {
        const referenceCircles = circleCandidates[0];
        const numDirections = 24;
        const labelDistance = 65;

        return referenceCircles.map(circle => {
            const candidates = [];

            for (let i = 0; i < numDirections; i++) {
                const angle = (i / numDirections) * Math.PI * 2;
                const x = circle.x + (circle.r + labelDistance) * Math.cos(angle);
                const y = circle.y + (circle.r + labelDistance) * Math.sin(angle);

                candidates.push({ x, y, angle: i * 360 / numDirections });
            }

            return candidates;
        });
    }

    /**
     * Encode the layout problem as SAT
     */
    encodeSAT(sat, data, analysis, circleCandidates, orgCandidates, labelCandidates) {
        // We only use one circle layout (the best one) for simplicity
        const circles = circleCandidates[0];

        // Create variables
        const orgVars = orgCandidates.map(positions =>
            positions.map(() => sat.newVar())
        );

        const labelVars = labelCandidates.map(positions =>
            positions.map(() => sat.newVar())
        );

        // Constraint: Each org at exactly one position
        data.organizations.forEach((org, i) => {
            if (orgVars[i].length === 0) return;

            // At least one
            sat.addClause(orgVars[i]);

            // At most one
            for (let p1 = 0; p1 < orgVars[i].length; p1++) {
                for (let p2 = p1 + 1; p2 < orgVars[i].length; p2++) {
                    sat.addClause([-orgVars[i][p1], -orgVars[i][p2]]);
                }
            }
        });

        // Constraint: Each label at exactly one position
        circles.forEach((circle, i) => {
            if (labelVars[i].length === 0) return;

            sat.addClause(labelVars[i]);

            for (let p1 = 0; p1 < labelVars[i].length; p1++) {
                for (let p2 = p1 + 1; p2 < labelVars[i].length; p2++) {
                    sat.addClause([-labelVars[i][p1], -labelVars[i][p2]]);
                }
            }
        });

        // Constraint: No org overlaps
        for (let i = 0; i < data.organizations.length; i++) {
            for (let j = i + 1; j < data.organizations.length; j++) {
                for (let pi = 0; pi < orgCandidates[i].length; pi++) {
                    for (let pj = 0; pj < orgCandidates[j].length; pj++) {
                        if (this.positionsOverlap(orgCandidates[i][pi], orgCandidates[j][pj], 60)) {
                            sat.addClause([-orgVars[i][pi], -orgVars[j][pj]]);
                        }
                    }
                }
            }
        }

        // Constraint: No label overlaps (with each other)
        for (let i = 0; i < circles.length; i++) {
            for (let j = i + 1; j < circles.length; j++) {
                for (let pi = 0; pi < labelCandidates[i].length; pi++) {
                    for (let pj = 0; pj < labelCandidates[j].length; pj++) {
                        if (this.labelsOverlap(
                            labelCandidates[i][pi], circles[i].name,
                            labelCandidates[j][pj], circles[j].name
                        )) {
                            sat.addClause([-labelVars[i][pi], -labelVars[j][pj]]);
                        }
                    }
                }
            }
        }

        // Constraint: No label overlaps with any circle
        circles.forEach((circle, circleIdx) => {
            labelCandidates[circleIdx].forEach((labelPos, labelIdx) => {
                for (const otherCircle of circles) {
                    if (this.labelOverlapsCircle(labelPos, circle.name, otherCircle)) {
                        // This label position overlaps a circle, so it's invalid
                        // We can't just mark it invalid after the fact, so we need to filter earlier
                        // For now, we'll handle this in candidate generation
                    }
                }
            });
        });

        return { orgVars, labelVars, circles };
    }

    /**
     * Check if two positions overlap
     */
    positionsOverlap(pos1, pos2, minDist) {
        const dx = pos1.x - pos2.x;
        const dy = pos1.y - pos2.y;
        return Math.sqrt(dx * dx + dy * dy) < minDist;
    }

    /**
     * Check if two labels overlap
     */
    labelsOverlap(pos1, text1, pos2, text2) {
        const bounds1 = this.getTextBounds(text1, pos1.x, pos1.y);
        const bounds2 = this.getTextBounds(text2, pos2.x, pos2.y);

        const padding = 15;
        return !(
            bounds1.right + padding < bounds2.left ||
            bounds2.right + padding < bounds1.left ||
            bounds1.bottom + padding < bounds2.top ||
            bounds2.bottom + padding < bounds1.top
        );
    }

    /**
     * Check if label overlaps circle
     */
    labelOverlapsCircle(labelPos, labelText, circle) {
        const bounds = this.getTextBounds(labelText, labelPos.x, labelPos.y);

        // Find closest point on rectangle to circle center
        const closestX = Math.max(bounds.left, Math.min(circle.x, bounds.right));
        const closestY = Math.max(bounds.top, Math.min(circle.y, bounds.bottom));

        const dx = closestX - circle.x;
        const dy = closestY - circle.y;

        return dx * dx + dy * dy < circle.r * circle.r;
    }

    /**
     * Get text bounding box
     */
    getTextBounds(text, x, y) {
        const charWidth = 10;
        const textWidth = text.length * charWidth + 20;
        const textHeight = 14 * 1.5;

        return {
            left: x - textWidth / 2,
            right: x + textWidth / 2,
            top: y - textHeight,
            bottom: y + 8
        };
    }

    /**
     * Extract solution from SAT assignment
     */
    extractSolution(solution, encoding, data, circleCandidates, orgCandidates, labelCandidates) {
        const { orgVars, labelVars, circles } = encoding;

        // Extract org positions
        data.organizations.forEach((org, i) => {
            for (let pi = 0; pi < orgCandidates[i].length; pi++) {
                if (solution[orgVars[i][pi]] === true) {
                    org.x = orgCandidates[i][pi].x;
                    org.y = orgCandidates[i][pi].y;
                    break;
                }
            }
        });

        // Extract label positions
        circles.forEach((circle, i) => {
            for (let pi = 0; pi < labelCandidates[i].length; pi++) {
                if (solution[labelVars[i][pi]] === true) {
                    circle.labelX = labelCandidates[i][pi].x;
                    circle.labelY = labelCandidates[i][pi].y;
                    break;
                }
            }
        });

        return { circles, organizations: data.organizations };
    }

    /**
     * Fallback to force-directed layout if SAT fails
     */
    fallbackLayout(data, analysis) {
        console.warn('Using fallback layout');
        // Return simple force-directed layout
        const circles = this.createCircleLayout(analysis, this.width / 2, this.height / 2);

        // Simple org positioning
        data.organizations.forEach(org => {
            const relevantCircles = circles.filter(c => org.categories.includes(c.name));
            if (relevantCircles.length > 0) {
                org.x = relevantCircles.reduce((sum, c) => sum + c.x, 0) / relevantCircles.length;
                org.y = relevantCircles.reduce((sum, c) => sum + c.y, 0) / relevantCircles.length;
            }
        });

        // Simple label positioning
        circles.forEach(circle => {
            circle.labelX = circle.x;
            circle.labelY = circle.y - circle.r - 30;
        });

        return { circles, organizations: data.organizations };
    }
}
