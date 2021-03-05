namespace IsbnSearch {

    open Microsoft.Quantum.Canon; // ApplyControlledOnInt, ApplyToEachCA
    open Microsoft.Quantum.Intrinsic; // X, H, Z
    open Microsoft.Quantum.Arithmetic; 
    // ApplyXorInPlace, MultiplyAndAddByModularInteger, LittleEndian, MeasureInteger
    open Microsoft.Quantum.Arrays; // ConstantArray, Most, Tail, Enumerated
    open Microsoft.Quantum.Convert; // IntAsDouble
    open Microsoft.Quantum.Math; // ArcSin, Sqrt, Round, PI, ComplexPolar
    open Microsoft.Quantum.Preparation; // PrepareArbitraryStateCP
    open Microsoft.Quantum.Diagnostics; // EqualityFactI, DumpMachine


    @EntryPoint()
    operation SearchForMissingDigit() : Unit {

        // define the incomplete ISBN, missing digit at -1
        let inputISBN = [0, 3, 0, 6, -1, 0, 6, 1, 5, 2];
        let constants = GetIsbnCheckConstants(inputISBN);
        let (a, b) = constants;

        Message($"ISBN with missing digit: {inputISBN}");
        Message($"Oracle validates: ({b} + {a}x) mod 11 = 0 \n");

        // get the number of Grover iterations required for 10 possible results and 1 solution
        let numIterations = NIterations(10);
        Message($"Optimal Grover iterations: {numIterations} \n");

        // Define the oracle
        let phaseOracle = IsbnOracle(constants, _);

        // Allocate 4-qubit register necessary to represent the possible values (digits 0-9)
        use digitReg = Qubit[4];
        mutable missingDigit = 0;
        mutable resultISBN = new Int[10];
        mutable attempts = 0;

        // Repeat the algorithm until the result forms a valid ISBN
        repeat{
            RunGroversSearch(digitReg, phaseOracle, numIterations);
            // print the resulting state of the system and then measure
            DumpMachine(); 
            set missingDigit = MeasureInteger(LittleEndian(digitReg));
            set resultISBN = MakeResultIsbn(missingDigit, inputISBN);
            // keep track of the number of attempts
            set attempts = attempts  + 1;
        } 
        until IsIsbnValid(resultISBN);

        // print the results
        Message($"Missing digit: {missingDigit}");
        Message($"Full ISBN: {resultISBN}");
        if attempts == 1 {
            Message($"The missing digit was found in {attempts} attempt.");
        }
        else {
            Message( $"The missing digit was found in {attempts} attempts.");
        }
    }


    operation ComputeIsbnCheck(constants : (Int, Int), digitReg : Qubit[], targetReg : Qubit[]) : Unit is Adj + Ctl {
        let (a, b) = constants;
        ApplyXorInPlace(b, LittleEndian(targetReg));
        MultiplyAndAddByModularInteger(a, 11, LittleEndian(digitReg), LittleEndian(targetReg));
    }

    /// # Summary
    /// Given an input four-qubit register, flags the "good" states with a phase factor of -1. 
    /// Those are the states |x⟩ such that (b + a*x) mod 11 = 0.
    ///
    /// # Description
    /// Allocates 1) a "flag" qubit puts it in the state |-⟩ to be used for phase kickback,  
    /// and 2) a qubit register of the same size as the input. 
    /// Both are deallocated at the end of the call. 
    /// The latter serves as the target for the arithmetic mapping 
    /// |x⟩|0⟩ -> |x⟩ |(b + a*x) mod 11 ⟩ handled in `ComputeIsbnCheck`. Then, the target register
    /// being in number state |0⟩ controls an X operation on the flag qubit, providing the phase 
    /// factor to the proper states.
    ///
    /// # Input
    /// ## constants
    /// The tuple (a, b) of the values which result from the ISBN and which digit is missing. 
    /// ## digitReg
    /// The input four-qubit register which will be operated on.
    /// These imply the ISBN check equation 0 = b + a*x mod 11.
    operation IsbnOracle(constants : (Int, Int), digitReg : Qubit[]) : Unit is Adj + Ctl {
        use (targetReg, flagQubit) = (Qubit[Length(digitReg)], Qubit());
        within {
            X(flagQubit);
            H(flagQubit);
            ComputeIsbnCheck(constants, digitReg, targetReg);
        } apply {
            ApplyControlledOnInt(0, X, targetReg, flagQubit);
        }
    }


    function GetIsbnCheckConstants(digits : Int[]) : (Int, Int) {
        EqualityFactI(Length(digits), 10, "Expected a 10-digit number.");
        mutable a = 0;
        mutable b = 0;
        for (idx, digit) in Enumerated(digits) {
            if digit < 0 {
                set a = 10 - idx;
            }
            else {
                set b += (10 - idx) * digit;
            } 
        }
        return (a, b % 11);
    }


    function NIterations(nItems : Int) : Int {
        let angle = ArcSin(1. / Sqrt(IntAsDouble(nItems)));
        let nIterations = Round(0.25 * PI() / angle - 0.5);
        return nIterations;
    }


    operation PrepareUniformSuperpositionOverDigits(digitReg : Qubit[]) : Unit is Adj + Ctl {
        PrepareArbitraryStateCP(ConstantArray(10, ComplexPolar(1.0, 0.0)), LittleEndian(digitReg));
    }


    operation ReflectAboutUniform(digitReg : Qubit[]) : Unit {
        within {
            Adjoint PrepareUniformSuperpositionOverDigits(digitReg);
            ApplyToEachCA(X, digitReg);
        } apply {
            Controlled Z(Most(digitReg), Tail(digitReg));
        }
    }


    function IsIsbnValid(digits : Int[]) : Bool {
        EqualityFactI(Length(digits), 10, "Expected a 10-digit number.");
        mutable acc = 0;
        for (idx, digit) in Enumerated(digits) {
            set acc += (10 - idx) * digit;
        }
        return acc % 11 == 0;
    }


    function MakeResultIsbn(missingDigit : Int, inputISBN : Int[]) : Int[] {
        mutable resultISBN = new Int[Length(inputISBN)];
        for i in 0..Length(inputISBN) - 1 {
            if inputISBN[i] < 0 {
                set resultISBN w/= i <- missingDigit;
            }
            else {
                set resultISBN w/= i <- inputISBN[i];
            }
        }
        return resultISBN;
    }


    operation RunGroversSearch(register : Qubit[], phaseOracle : ((Qubit[]) => Unit is Adj), iterations : Int) : Unit {
        PrepareUniformSuperpositionOverDigits(register);
        for _ in 1 .. iterations {
            phaseOracle(register);
            ReflectAboutUniform(register);
        }
    }

}
