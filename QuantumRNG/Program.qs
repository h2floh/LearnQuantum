namespace QuantumRNG {

    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;

    operation GenerateRandomBit() : Result {
        // Allocate a qubit.
        use q = Qubit() {
            // Put the qubit to superposition.
            H(q);
            // It now has a 50% chance of being measured 0 or 1.
            // Measure the qubit value.
            return MResetZ(q);
        }
    }

    operation SampleRandomNumberInRange(min: Int, max : Int) : Int {
        mutable output = 0; 
        repeat {
            mutable bits = new Result[0]; 
            for idxBit in 1..BitSizeI(max) {
                set bits += [GenerateRandomBit()]; 
            }
            set output = ResultArrayAsInt(bits);
        } until (output >= min and output <= max);
        return output;
    }

    @EntryPoint()
    operation SampleRandomNumber() : Bool {
        let max = 50;
        let min = 10;
        mutable index = 0;
        
        Message($"Sampling a random number between {min} and {max}: ");
        repeat {
            let result = SampleRandomNumberInRange(min, max);
            Message($"{index}#: {result}");
            set index += 1;
        } until (index > 100);

        return true;
    }
}

