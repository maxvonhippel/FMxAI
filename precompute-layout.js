#!/usr/bin/env node
/**
 * precompute-layout.js
 *
 * Self-contained layout precomputation using Z3 as the constraint solver.
 * Reads data.json, generates candidate positions for circles/orgs/labels,
 * encodes overlap constraints with Z3's high-level API, solves, and writes
 * layout-cache.json.
 */

'use strict';

const fs = require('fs');

// ---------------------------------------------------------------------------
// Tunable parameters
// ---------------------------------------------------------------------------
const ORG_DOT_MIN_DIST    = 40;  // minimum px between org dot centres
const ORG_LABEL_PADDING   = 5;   // px padding in org-label overlap check
const ORG_GRID_STEP       = 15;  // grid resolution for org candidate generation
const ORG_CANDIDATE_LIMIT = 150; // max candidates kept per org

// ---------------------------------------------------------------------------
// Geometry helpers
// ---------------------------------------------------------------------------

function positionsOverlap(pos1, pos2, minDist) {
    const dx = pos1.x - pos2.x;
    const dy = pos1.y - pos2.y;
    return Math.sqrt(dx * dx + dy * dy) < minDist;
}

function getTextBounds(text, x, y) {
    const charWidth = 10; // 14px font
    const textWidth = text.length * charWidth + 40;
    const textHeight = 14 * 1.5;
    return {
        left:   x - textWidth / 2,
        right:  x + textWidth / 2,
        top:    y - textHeight,
        bottom: y + 10
    };
}

function getOrgTextBounds(text, x, y) {
    const charWidth = 9; // 12px font
    const textWidth = text.length * charWidth + 30;
    const textHeight = 12 * 1.5;
    return {
        left:   x - textWidth / 2,
        right:  x + textWidth / 2,
        top:    y - textHeight,
        bottom: y + 10
    };
}

function labelsOverlap(pos1, text1, pos2, text2) {
    const b1 = getTextBounds(text1, pos1.x, pos1.y);
    const b2 = getTextBounds(text2, pos2.x, pos2.y);
    const padding = 20;
    return !(
        b1.right  + padding < b2.left  ||
        b2.right  + padding < b1.left  ||
        b1.bottom + padding < b2.top   ||
        b2.bottom + padding < b1.top
    );
}

function orgLabelsOverlap(pos1, text1, pos2, text2) {
    const b1 = getOrgTextBounds(text1, pos1.x, pos1.y);
    const b2 = getOrgTextBounds(text2, pos2.x, pos2.y);
    const padding = ORG_LABEL_PADDING;
    return !(
        b1.right  + padding < b2.left  ||
        b2.right  + padding < b1.left  ||
        b1.bottom + padding < b2.top   ||
        b2.bottom + padding < b1.top
    );
}

function labelOverlapsCircle(labelPos, labelText, circle) {
    const bounds = getTextBounds(labelText, labelPos.x, labelPos.y);
    const closestX = Math.max(bounds.left,  Math.min(circle.x, bounds.right));
    const closestY = Math.max(bounds.top,   Math.min(circle.y, bounds.bottom));
    const dx = closestX - circle.x;
    const dy = closestY - circle.y;
    return dx * dx + dy * dy < circle.r * circle.r;
}

// ---------------------------------------------------------------------------
// Relationship analysis
// ---------------------------------------------------------------------------

function analyzeRelationships(data) {
    return data.categories.map((cat, i) => ({
        index: i,
        name:  cat.name,
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

// ---------------------------------------------------------------------------
// Circle layout (force simulation)
// ---------------------------------------------------------------------------

function createCircleLayout(analysis, centerX, centerY) {
    const circles = analysis.map((cat, i) => {
        const radius = 80 + (cat.orgCount / Math.max(...analysis.map(c => c.orgCount))) * 80;
        const angle = (i / analysis.length) * Math.PI * 2;
        const distance = 150;
        return {
            index: i,
            name:  cat.name,
            color: cat.color,
            x: centerX + Math.cos(angle) * distance,
            y: centerY + Math.sin(angle) * distance,
            r: radius
        };
    });

    for (let iter = 0; iter < 200; iter++) {
        circles.forEach(c => { c.fx = 0; c.fy = 0; });

        for (let i = 0; i < circles.length; i++) {
            for (let j = i + 1; j < circles.length; j++) {
                const dx   = circles[j].x - circles[i].x;
                const dy   = circles[j].y - circles[i].y;
                const dist = Math.sqrt(dx * dx + dy * dy) || 1;
                const shouldOverlap = analysis[i].overlaps[j] > 0;

                if (shouldOverlap) {
                    const target = (circles[i].r + circles[j].r) * 0.7;
                    const force  = (dist - target) * 0.02;
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

        circles.forEach(c => {
            c.x += c.fx * 0.9;
            c.y += c.fy * 0.9;
        });
    }

    return circles;
}

function generateCircleCandidates(analysis, width, height) {
    const centerX = width  / 2;
    const centerY = height / 2;
    const candidates = [];

    candidates.push(createCircleLayout(analysis, centerX, centerY));

    for (let variant = 0; variant < 5; variant++) {
        candidates.push(createCircleLayout(
            analysis,
            centerX + (variant - 2) * 50,
            centerY + (variant - 2) * 50
        ));
    }

    return candidates;
}

// ---------------------------------------------------------------------------
// Org candidate generation (grid within constraint regions)
// ---------------------------------------------------------------------------

function generateOrgCandidates(organizations, circleCandidates) {
    const referenceCircles = circleCandidates[0];
    const gridStep = ORG_GRID_STEP;

    return organizations.map(org => {
        const candidates = [];

        const requiredCircles = referenceCircles.filter(c =>
            org.categories.includes(c.name)
        );

        if (requiredCircles.length === 0) return [];

        const minX = Math.min(...requiredCircles.map(c => c.x - c.r));
        const maxX = Math.max(...requiredCircles.map(c => c.x + c.r));
        const minY = Math.min(...requiredCircles.map(c => c.y - c.r));
        const maxY = Math.max(...requiredCircles.map(c => c.y + c.r));

        for (let x = minX; x <= maxX; x += gridStep) {
            for (let y = minY; y <= maxY; y += gridStep) {
                let valid = true;

                for (const circle of referenceCircles) {
                    const dx   = x - circle.x;
                    const dy   = y - circle.y;
                    const dist = Math.sqrt(dx * dx + dy * dy);
                    const shouldBeIn = org.categories.includes(circle.name);

                    if (shouldBeIn  && dist >= circle.r - 15) { valid = false; break; }
                    if (!shouldBeIn && dist <  circle.r + 25) { valid = false; break; }
                }

                if (valid) {
                    let minDistToEdge = Infinity;
                    for (const circle of referenceCircles) {
                        const dx   = x - circle.x;
                        const dy   = y - circle.y;
                        const dist = Math.sqrt(dx * dx + dy * dy);
                        const shouldBeIn = org.categories.includes(circle.name);
                        const edgeDist = shouldBeIn ? circle.r - dist : dist - circle.r;
                        minDistToEdge = Math.min(minDistToEdge, edgeDist);
                    }
                    candidates.push({ x, y, score: minDistToEdge });
                }
            }
        }

        candidates.sort((a, b) => b.score - a.score);
        return candidates.slice(0, ORG_CANDIDATE_LIMIT);
    });
}

// ---------------------------------------------------------------------------
// Label candidate generation (radial positions around each circle)
// ---------------------------------------------------------------------------

function generateLabelCandidates(circleCandidates) {
    const referenceCircles = circleCandidates[0];
    const numDirections = 32;
    const labelDistance = 70;

    return referenceCircles.map((circle) => {
        const candidates = [];

        for (let i = 0; i < numDirections; i++) {
            const angle = (i / numDirections) * Math.PI * 2;
            const x = circle.x + (circle.r + labelDistance) * Math.cos(angle);
            const y = circle.y + (circle.r + labelDistance) * Math.sin(angle);

            let overlapsAnyCircle = false;
            for (const otherCircle of referenceCircles) {
                if (labelOverlapsCircle({ x, y }, circle.name, otherCircle)) {
                    overlapsAnyCircle = true;
                    break;
                }
            }

            if (!overlapsAnyCircle) {
                candidates.push({
                    x,
                    y,
                    angle:     i * 360 / numDirections,
                    direction: `${(i * 360 / numDirections).toFixed(0)}°`
                });
            }
        }

        if (candidates.length < 8) {
            console.warn(`${circle.name} label has only ${candidates.length} valid positions (filtered from ${numDirections})`);
        }

        return candidates;
    });
}

// ---------------------------------------------------------------------------
// Fallback layout (used when Z3 returns unsat / unknown)
// ---------------------------------------------------------------------------

function fallbackLayout(data, analysis, width, height) {
    console.warn('Using fallback layout');
    const circles = createCircleLayout(analysis, width / 2, height / 2);

    data.organizations.forEach(org => {
        const relevant = circles.filter(c => org.categories.includes(c.name));
        if (relevant.length > 0) {
            org.x = relevant.reduce((s, c) => s + c.x, 0) / relevant.length;
            org.y = relevant.reduce((s, c) => s + c.y, 0) / relevant.length;
        }
    });

    circles.forEach(circle => {
        circle.labelX = circle.x;
        circle.labelY = circle.y - circle.r - 30;
    });

    return { circles, organizations: data.organizations };
}

// ---------------------------------------------------------------------------
// Solution extraction from Z3 model
// ---------------------------------------------------------------------------

function extractSolution(model, orgVarNames, labelVarNames, evalFn,
                          data, circles, orgCandidates, labelCandidates) {
    // Extract org positions
    data.organizations.forEach((org, i) => {
        for (let pi = 0; pi < orgCandidates[i].length; pi++) {
            if (evalFn(orgVarNames[i][pi]) === 'true') {
                org.x = orgCandidates[i][pi].x;
                org.y = orgCandidates[i][pi].y;
                break;
            }
        }
    });

    // Extract label positions
    circles.forEach((circle, i) => {
        for (let pi = 0; pi < labelCandidates[i].length; pi++) {
            if (evalFn(labelVarNames[i][pi]) === 'true') {
                circle.labelX = labelCandidates[i][pi].x;
                circle.labelY = labelCandidates[i][pi].y;
                break;
            }
        }
    });

    // Verify
    console.log('Verifying solution...');
    let hasErrors = false;

    for (let i = 0; i < circles.length; i++) {
        for (let j = i + 1; j < circles.length; j++) {
            if (labelsOverlap(
                { x: circles[i].labelX, y: circles[i].labelY }, circles[i].name,
                { x: circles[j].labelX, y: circles[j].labelY }, circles[j].name
            )) {
                console.error(`✗ Labels overlap: ${circles[i].name} ↔ ${circles[j].name}`);
                hasErrors = true;
            }
        }
    }

    for (let i = 0; i < circles.length; i++) {
        for (let j = 0; j < circles.length; j++) {
            if (labelOverlapsCircle(
                { x: circles[i].labelX, y: circles[i].labelY },
                circles[i].name,
                circles[j]
            )) {
                console.error(`✗ Label overlaps circle: ${circles[i].name} label ↔ ${circles[j].name} circle`);
                hasErrors = true;
            }
        }
    }

    for (let i = 0; i < data.organizations.length; i++) {
        for (let j = i + 1; j < data.organizations.length; j++) {
            if (positionsOverlap(data.organizations[i], data.organizations[j], ORG_DOT_MIN_DIST)) {
                console.error(`✗ Org dots overlap: ${data.organizations[i].name} ↔ ${data.organizations[j].name}`);
                hasErrors = true;
            }
        }
    }

    for (let i = 0; i < data.organizations.length; i++) {
        for (let j = i + 1; j < data.organizations.length; j++) {
            const lp1 = { x: data.organizations[i].x, y: data.organizations[i].y + 20 };
            const lp2 = { x: data.organizations[j].x, y: data.organizations[j].y + 20 };
            if (orgLabelsOverlap(lp1, data.organizations[i].name, lp2, data.organizations[j].name)) {
                console.error(`✗ Org labels overlap: ${data.organizations[i].name} ↔ ${data.organizations[j].name}`);
                hasErrors = true;
            }
        }
    }

    if (!hasErrors) {
        console.log('✓ Solution verified: no overlaps detected');
    }

    return { circles, organizations: data.organizations };
}

// ---------------------------------------------------------------------------
// Main async IIFE
// ---------------------------------------------------------------------------

(async () => {
    console.log('=== Unified Layout Optimization (Z3) ===');

    // 1. Read data
    const data = JSON.parse(fs.readFileSync('./data.json', 'utf8'));

    const WIDTH  = 1000;
    const HEIGHT = 800;

    // 2. Generate candidates
    const analysis        = analyzeRelationships(data);
    const circleCandidates = generateCircleCandidates(analysis, WIDTH, HEIGHT);
    const orgCandidates    = generateOrgCandidates(data.organizations, circleCandidates);
    const labelCandidates  = generateLabelCandidates(circleCandidates);

    const circles = circleCandidates[0]; // reference layout

    console.log(
        `Candidates: ${circleCandidates.length} circle sets, ` +
        `${orgCandidates.reduce((s, c) => s + c.length, 0)} org positions, ` +
        `${labelCandidates.reduce((s, c) => s + c.length, 0)} label positions`
    );

    // 3. Initialise Z3
    const { init } = require('z3-solver');
    const { Context } = await init();
    const { Solver, Bool, Or, Not, And, AtMost, Implies } = new Context('main');

    const solver = new Solver();

    // --- Create boolean variables ---
    // orgVars[i][p]   : org i is placed at candidate position p
    // labelVars[i][p] : label i is placed at candidate position p
    const orgVarObjs   = orgCandidates.map((positions, i) =>
        positions.map((_, p) => Bool.const(`org_${i}_${p}`))
    );
    const labelVarObjs = labelCandidates.map((positions, i) =>
        positions.map((_, p) => Bool.const(`lbl_${i}_${p}`))
    );

    // --- Constraint: each org at exactly one position ---
    data.organizations.forEach((org, i) => {
        if (orgVarObjs[i].length === 0) {
            console.warn(`No valid positions for org: ${org.name}`);
            return;
        }
        // At least one
        solver.add(Or(...orgVarObjs[i]));
        // At most one  (Z3 built-in cardinality — O(n) instead of O(n^2))
        solver.add(AtMost(orgVarObjs[i], 1));
    });

    // --- Constraint: each label at exactly one position ---
    circles.forEach((circle, i) => {
        if (labelVarObjs[i].length === 0) {
            console.warn(`No valid positions for label: ${circle.name}`);
            return;
        }
        solver.add(Or(...labelVarObjs[i]));
        solver.add(AtMost(labelVarObjs[i], 1));
    });

    // --- Constraint: no org dot overlaps ---
    let orgOverlapConstraints = 0;
    for (let i = 0; i < data.organizations.length; i++) {
        for (let j = i + 1; j < data.organizations.length; j++) {
            for (let pi = 0; pi < orgCandidates[i].length; pi++) {
                for (let pj = 0; pj < orgCandidates[j].length; pj++) {
                    if (positionsOverlap(orgCandidates[i][pi], orgCandidates[j][pj], ORG_DOT_MIN_DIST)) {
                        // Implies(org_i_pi, Not(org_j_pj))
                        solver.add(Implies(orgVarObjs[i][pi], Not(orgVarObjs[j][pj])));
                        orgOverlapConstraints++;
                    }
                }
            }
        }
    }
    console.log(`Added ${orgOverlapConstraints} org-org dot anti-overlap constraints`);

    // --- Constraint: no org label overlaps ---
    let orgLabelOverlapConstraints = 0;
    for (let i = 0; i < data.organizations.length; i++) {
        for (let j = i + 1; j < data.organizations.length; j++) {
            for (let pi = 0; pi < orgCandidates[i].length; pi++) {
                for (let pj = 0; pj < orgCandidates[j].length; pj++) {
                    const lp1 = { x: orgCandidates[i][pi].x, y: orgCandidates[i][pi].y + 20 };
                    const lp2 = { x: orgCandidates[j][pj].x, y: orgCandidates[j][pj].y + 20 };
                    if (orgLabelsOverlap(lp1, data.organizations[i].name, lp2, data.organizations[j].name)) {
                        solver.add(Implies(orgVarObjs[i][pi], Not(orgVarObjs[j][pj])));
                        orgLabelOverlapConstraints++;
                    }
                }
            }
        }
    }
    console.log(`Added ${orgLabelOverlapConstraints} org-org label anti-overlap constraints`);

    // --- Constraint: no circle-label overlaps with each other ---
    let labelOverlapConstraints = 0;
    for (let i = 0; i < circles.length; i++) {
        for (let j = i + 1; j < circles.length; j++) {
            let pairConstraints = 0;
            for (let pi = 0; pi < labelCandidates[i].length; pi++) {
                for (let pj = 0; pj < labelCandidates[j].length; pj++) {
                    if (labelsOverlap(
                        labelCandidates[i][pi], circles[i].name,
                        labelCandidates[j][pj], circles[j].name
                    )) {
                        solver.add(Implies(labelVarObjs[i][pi], Not(labelVarObjs[j][pj])));
                        pairConstraints++;
                        labelOverlapConstraints++;
                    }
                }
            }
            const totalPairs = labelCandidates[i].length * labelCandidates[j].length;
            if (pairConstraints > totalPairs * 0.8) {
                console.warn(
                    `High overlap between ${circles[i].name} and ${circles[j].name} labels: ` +
                    `${pairConstraints}/${totalPairs} position pairs conflict`
                );
            }
        }
    }
    console.log(`Added ${labelOverlapConstraints} label-label anti-overlap constraints`);

    // Note: label-circle overlap is already filtered out in generateLabelCandidates.

    // 4. Solve
    console.log('Solving with Z3...');
    const result = await solver.check();
    console.log(`Z3 result: ${result}`);

    let layout;

    if (result === 'sat') {
        console.log('✓ Solution found!');
        const model = solver.model();

        // Build name→Bool-var maps for extraction helper
        const orgVarNames   = orgVarObjs.map(row => row.map(v => v));
        const labelVarNames = labelVarObjs.map(row => row.map(v => v));

        const evalFn = (boolVar) => model.eval(boolVar).toString();

        layout = extractSolution(
            model, orgVarNames, labelVarNames, evalFn,
            data, circles, orgCandidates, labelCandidates
        );
    } else {
        console.error(`Z3 returned ${result}. Falling back to force-directed layout.`);
        layout = fallbackLayout(data, analysis, WIDTH, HEIGHT);
    }

    // 5. Write output
    fs.writeFileSync('./layout-cache.json', JSON.stringify(layout, null, 2));
    console.log('layout-cache.json written.');
})().catch(err => {
    console.error('Fatal error:', err);
    process.exit(1);
});
