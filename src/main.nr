use dep::std;

const N: Field = 32;
const numHashers: Field = 31;

// TODO: hashers should be dynamically sized based on 
// let numHashers = totalLeaves - 1;
fn merkle_root(leaves: [Field]) -> Field {
    let totalLeaves : const Field = std::array::len(leaves);

    let mut hashers : [Field; numHashers] = [0; 31];

    let numLeafHashers : const Field = totalLeaves / 2;
    let numIntermediateHashers : const Field = numLeafHashers - 1;

    for i in 0..numLeafHashers {
        hashers[i] = std::hash::pedersen([leaves[i*2], leaves[i*2+1]])[0];
    };

    let mut k = 0;
    for i in numLeafHashers..numLeafHashers + numIntermediateHashers {
        hashers[i] = std::hash::pedersen([hashers[k*2], hashers[k*2+1]])[0];

        k = k + 1;
    };

    hashers[numLeafHashers - 1]
}

// TODO: add inexact transfers
fn process_events(
    froms: [Field],
    tos: [Field],
    values: [Field],
) -> [Field; 2] {
    let mut balances : [Field; N] = [0 ; 32];

    for i in 0..N {
        let mut fromBalance = 0;
        for j in 0..N {
            if froms[i] == tos[j] {
                fromBalance = balances[j];
            }
        };

        for j in 0..N {
            // If you are the sender of the event
            if froms[i] == tos[j] {
                // If the event is a deposit OR the sender has sufficient funds
                if (froms[i] == 0) | (fromBalance == values[i]) {
                    balances[j] = balances[j] - values[i];
                }
            }
            // If you are the recipient of the event
            if tos[i] == tos[j] {
                // If the event is a deposit OR the sender has sufficient funds
                if (froms[i] == 0) | (fromBalance == values[i]) {
                    balances[j] = balances[j] + values[i];
                } 
            }
        };
    };

    let mut eventHash = 0;
    let mut stateHashes : [Field; N] = [0 ; 32];

    for i in 0..N {
        // If both accounts are zero, these are just default signals; we have processed all events
        if (froms[i] != 0) | (tos[i] != 0) {
            eventHash = std::hash::pedersen([eventHash, froms[i], tos[i], values[i]])[0];
        }

        stateHashes[i] = std::hash::pedersen([tos[i], balances[i]])[0];
    };

    [eventHash, merkle_root(stateHashes)]
}

fn main(
    froms : [Field; N], 
    tos : [Field; N], 
    values : [Field; N], 
) -> pub [Field; 2] {
    process_events(froms, tos, values)
}
