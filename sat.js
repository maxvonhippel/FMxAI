/**
 * Simple SAT solver using DPLL algorithm
 * (Davis-Putnam-Logemann-Loveland)
 *
 * Solves Boolean satisfiability problems in Conjunctive Normal Form (CNF).
 * A formula is in CNF if it's an AND of ORs of literals.
 *
 * Example:
 *   const sat = new SATSolver();
 *   const x = sat.newVar();
 *   const y = sat.newVar();
 *   sat.addClause([x, y]);      // x OR y
 *   sat.addClause([-x, y]);     // NOT x OR y
 *   const solution = sat.solve(); // returns assignment or null
 */
class SATSolver {
    constructor() {
        this.clauses = [];
        this.numVars = 0;
    }

    /**
     * Create a new Boolean variable
     * @returns {number} Variable ID (positive integer)
     */
    newVar() {
        return ++this.numVars;
    }

    /**
     * Add a clause (disjunction of literals)
     * @param {number[]} literals - Array of variable IDs (negative = negated)
     */
    addClause(literals) {
        this.clauses.push(literals);
    }

    /**
     * Solve the SAT problem
     * @returns {(number[]|null)} Assignment array (indexed by var ID) or null if UNSAT
     */
    solve() {
        const assignment = new Array(this.numVars + 1).fill(undefined);
        return this.dpll(assignment);
    }

    /**
     * DPLL recursive search with backtracking
     * @private
     */
    dpll(assignment) {
        // Check all clauses
        let allSatisfied = true;
        for (const clause of this.clauses) {
            const result = this.evalClause(clause, assignment);
            if (result === false) {
                return null; // Conflict - backtrack
            }
            if (result === undefined) {
                allSatisfied = false;
            }
        }

        // All clauses satisfied - solution found!
        if (allSatisfied) {
            return assignment;
        }

        // Choose next unassigned variable
        let nextVar = -1;
        for (let i = 1; i <= this.numVars; i++) {
            if (assignment[i] === undefined) {
                nextVar = i;
                break;
            }
        }

        if (nextVar === -1) {
            return assignment; // All assigned
        }

        // Try true
        assignment[nextVar] = true;
        const resultTrue = this.dpll(assignment);
        if (resultTrue) return resultTrue;

        // Try false
        assignment[nextVar] = false;
        const resultFalse = this.dpll(assignment);
        if (resultFalse) return resultFalse;

        // Backtrack
        assignment[nextVar] = undefined;
        return null;
    }

    /**
     * Evaluate a clause given current assignment
     * @private
     * @returns {(boolean|undefined)} true=satisfied, false=conflict, undefined=unknown
     */
    evalClause(clause, assignment) {
        let hasUndefined = false;

        for (const lit of clause) {
            const varIdx = Math.abs(lit);
            const val = assignment[varIdx];

            if (val === undefined) {
                hasUndefined = true;
            } else {
                const litVal = lit > 0 ? val : !val;
                if (litVal) {
                    return true; // Clause satisfied
                }
            }
        }

        return hasUndefined ? undefined : false;
    }
}
