namespace ExploreGroversSearch {

    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Intrinsic;

    // @EntryPoint()
    operation DemoSolveGraphColoringProblem() : Unit {
        // Graph description: hardcoded from the example
        // https://docs.microsoft.com/en-us/learn/modules/solve-graph-coloring-problems-grovers-search/4-implement-quantum-oracle
        // The number of vertices is an integer
        let nVertices = 5;
        // The list of edges is an array of tuples, and each tuple is a pair of integers
        let edges = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4)];

        // Graph coloring: hardcoded from the example
        // valid - let coloring = [false, false, true, false, false, true, true, true, true, false];
        // invalid
        let coloring = [false, false, true, false, false, true, true, true, true, true];
        let colors = ["red", "green", "blue", "yellow"];

        // Interpret the coloring: split the bit string into 2-bit fragments and convert them to colors.
        let colorBits = Chunks(2, coloring);
        for i in 0 .. nVertices - 1 {
            let colorIndex = BoolArrayAsInt(colorBits[i]);
            Message($"Vertex {i} - color #{colorIndex} ({colors[colorIndex]})");
        }
    }

    operation MarkColorEquality(c0 : Qubit[], c1 : Qubit[], target : Qubit) : Unit is Adj+Ctl {
        // https://docs.microsoft.com/en-us/azure/quantum/user-guide/language/statements/conjugations
        within {
            // Iterate over pairs of qubits in matching positions in c0 and c1.
            for (q0, q1) in Zipped(c0, c1) {
                // Compute XOR of bits q0 and q1 in place (storing it in q1).
                CNOT(q0, q1);
                // Message("within - comparing qubits in matchin positions - c1:");
                // DumpRegister((), c1);
            }
        } apply {
            // https://docs.microsoft.com/en-us/qsharp/api/qsharp/microsoft.quantum.canon.controlledonint
            // If all computed XORs are 0, the bit strings are equal - flip the state of the target.
            (ControlledOnInt(0, X))(c1, target);
            // Message("apply if all computed XORs are 0, c1, target:");
            // DumpRegister((), c1 + [target]);
        }
    }


    // @EntryPoint()
    operation ShowColorEqualityCheck() : Unit {
        use (c0, c1, target) = (Qubit[2], Qubit[2], Qubit());
        // Leave register c0 in the |00⟩ state.

        // Prepare a quantum state that is a superposition of all possible colors on register c1.
        ApplyToEach(H, c1);

        // Output the initial state of qubits c1 and target. 
        // We do not include the state of qubits in the register c0 for brevity, 
        // since they will remain |00⟩ throughout the program.
        Message("The starting state of qubits c1 and target:");
        DumpRegister((), c1 + [target]);

        // Compare registers and mark the result in target qubit.
        MarkColorEquality(c0, c1, target);

        Message("");
        Message("The state of qubits c1 and target after the equality check:");
        DumpRegister((), c1 + [target]);

        // Return the qubits to |0⟩ state before releasing them.
        ResetAll(c1 + [target]);
    }

    operation MarkValidVertexColoring(
        edges : (Int, Int)[], 
        colorsRegister : Qubit[], 
        target : Qubit
    ) : Unit is Adj+Ctl {
        let color_names = ["red", "green", "blue", "yellow"];
        let nEdges = Length(edges);
        // Split the register that encodes the colors into an array of two-qubit registers, one per color.
        let colors = Chunks(2, colorsRegister);
        // Allocate one extra qubit per edge to mark the edges that connect vertices with the same color.
        use conflictQubits = Qubit[nEdges];
        within {
            for ((start, end), conflictQubit) in Zipped(edges, conflictQubits) {
                // Check that the endpoints have different colors: apply MarkColorEquality operation; 
                // if the colors are the same, the result will be 1, indicating a conflict.
                // Message($"check color of nodes {start}-{end}:");
                MarkColorEquality(colors[start], colors[end], conflictQubit);
                // DumpRegister((), [conflictQubit]);
            }
        } apply {
            // If there are no conflicts (all qubits are in 0 state), the vertex coloring is valid.
            // DumpRegister((), [target]);
            (ControlledOnInt(0, X))(conflictQubits, target);
            // DumpRegister((), [target]);
        }
    }

    // @EntryPoint()
    operation ShowColoringValidationCheck() : Unit {
        // Graph description: hardcoded from the example
        let nVertices = 5;
        let edges = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4)];
        

        // Graph coloring: hardcoded from the example
        let coloring = [false, false, true, false, false, true, true, true, false, true]; // valid
        // let coloring = [false, false, true, false, false, true, true, true, true, true]; // invalid

        use (coloringRegister, target) = (Qubit[2 * nVertices], Qubit());
        // Encode the coloring in the quantum register:
        // apply an X gate to each qubit that corresponds to "true" bit in the bit string.
        ApplyPauliFromBitString(PauliX, true, coloring, coloringRegister);

        // apply Hadamard gate on input qubits
        // ApplyToEach(H, coloringRegister);
        // Message("The qubit input in a uniform superposition: ");
        // DumpRegister((), coloringRegister);

        // Apply the operation that will check whether the coloring is valid.
        MarkValidVertexColoring(edges, coloringRegister, target);

        // Print validation result.
        let isColoringValid = M(target) == One;
        Message($"The coloring is {isColoringValid ? "valid" | "invalid"}");

        // Return the qubits to |0⟩ state before releasing them.
        ResetAll(coloringRegister);
    }

    operation ApplyMarkingOracleAsPhaseOracle(
        markingOracle : ((Qubit[], Qubit[], Qubit) => Unit is Adj), 
        c0 : Qubit[],
        c1 : Qubit[]
    ) : Unit is Adj {
        use target = Qubit();
        within {
            // Put the target qubit into the |-⟩ state.
            X(target);
            H(target);
        } apply {
            // Apply the marking oracle; since the target is in the |-⟩ state,
            // flipping the target if the register state satisfies the condition 
            // will apply a -1 relative phase to the register state.
            markingOracle(c0, c1, target);
        }
    }

    // @EntryPoint()
    operation ShowPhaseKickbackTrick() : Unit {
        use (c0, c1) = (Qubit[2], Qubit[2]);
        // Leave register c0 in the |00⟩ state.

        // Prepare a quantum state that is a superposition of all possible colors on register c1.
        ApplyToEach(H, c1);

        // Output the initial state of qubits c1. 
        // We do not include the state of qubits in the register c0 for brevity, 
        // since they will remain |00⟩ throughout the program.
        Message("The starting state of qubits c1:");
        DumpRegister((), c1);

        // Compare registers and mark the result in their phase.
        ApplyMarkingOracleAsPhaseOracle(MarkColorEquality, c0, c1);

        Message("");
        Message("The state of qubits c1 after the equality check:");
        DumpRegister((), c1);

        // Return the qubits to |0⟩ state before releasing them.
        ResetAll(c1);
    }

    operation ApplyMarkingOracleAsPhaseOracle2(
        markingOracle : ((Qubit[], Qubit) => Unit is Adj), 
        register : Qubit[]
    ) : Unit is Adj {
        use target = Qubit();
        within {
            X(target);
            H(target);
        } apply {
            markingOracle(register, target);
        }
    }

    operation RunGroversSearch(register : Qubit[], phaseOracle : ((Qubit[]) => Unit is Adj), iterations : Int) : Unit {
        // Prepare an equal superposition of all basis states
        ApplyToEach(H, register);
        
        // Iterations of Grover's search
        for _ in 1 .. iterations {
            // Step 1: apply the oracle
            phaseOracle(register);
            // Step 2: reflection around the mean
            within {
                ApplyToEachA(H, register);
                ApplyToEachA(X, register);
            } apply {
                Controlled Z(Most(register), Tail(register));
            }
        }
    }

    @EntryPoint()
    operation SolveGraphColoringProblem() : Unit {
        // Graph description: hardcoded from the example.
        let nVertices = 5;
        let edges = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4)];

        // Define the oracle that implements this graph coloring.
        let markingOracle = MarkValidVertexColoring(edges, _, _);
        let phaseOracle = ApplyMarkingOracleAsPhaseOracle2(markingOracle, _);

        // Define the parameters of the search.
        
        // Each color is described using 2 bits (or qubits).
        let nQubits = 2 * nVertices;

        // The search space is all bit strings of length nQubits.
        let searchSpaceSize = 2 ^ (nQubits);

        // The number of solutions is the number of permutations of 4 colors (over the first four vertices) = 4!
        // multiplied by 3 colors that vertex 4 can take in each case.
        let nSolutions = 72;

        // The number of iterations can be computed using a formula.
        let nIterations = Round(PI() / 4.0 * Sqrt(IntAsDouble(searchSpaceSize) / IntAsDouble(nSolutions)));

        mutable answer = new Bool[nQubits];
        use (register, output) = (Qubit[nQubits], Qubit());
        mutable isCorrect = false;
        repeat {
            Message("RunGroversSearch");
            RunGroversSearch(register, phaseOracle, nIterations);
            let res = MultiM(register);
            // Check whether the result is correct.
            markingOracle(register, output);
            if (MResetZ(output) == One) {
                set isCorrect = true;
                set answer = ResultArrayAsBoolArray(res);
            }
            ResetAll(register);
        } until (isCorrect);
        // Convert the answer to readable format (actual graph coloring).
        let colorBits = Chunks(2, answer);
        Message("The resulting graph coloring:");
        for i in 0 .. nVertices - 1 {
            Message($"Vertex {i} - color {BoolArrayAsInt(colorBits[i])}");
        }
    }
}
