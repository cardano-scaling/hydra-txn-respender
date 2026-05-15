# Transaction respender

### Usage

First, you need the address that owns the UTxO you want to spend, and you need
a file in this folder called `key.sk` that is capable of signing messages.

I created this file by:

```
ln -s <hydra-path>/hydra-cluster/config/credentials/alice-funds.sk key.sk
```

Then, with he demo environment from hydra-node:

1. `nix run github:cardano-scaling/hydra#demo`.
2. Open all the terminals, init the head, have everyone commit some monies
3. Run `nix run . --  addr_test1vp5cxztpc6hep9ds7fjgmle3l225tk8ske3rmwr9adu0m6qchmx5z`
4. In one terminal, sign a new snapshot
5. Observe many snapshots now signed!

### Splitting a UTxO

You can optionally pass a second argument `N` to switch from "respend the whole
UTxO forever" into "split mode": each respend produces two outputs back to the
same address (instead of one), and the program exits after `N` splits.

In split mode every respend submits a **constant-size** transaction: one output
of a fixed `1_000_000` lovelace, plus a remainder output for the rest. The
split-off amount does not change between iterations, so every transaction has
the same shape and size:

| Iteration | Split-off output    | Remainder output         |
| --------- | ------------------- | ------------------------ |
| 1         | 1_000_000 lovelace  | `value − 1_000_000`      |
| 2         | 1_000_000 lovelace  | `value − 2_000_000`      |
| 3         | 1_000_000 lovelace  | `value − 3_000_000`      |
| ...       | ...                 | ...                      |
| `N`       | 1_000_000 lovelace  | `value − N · 1_000_000`  |

On each iteration the **largest** UTxO at the address is picked as the input,
so the small split-off pieces accumulate and the large "remainder" is what
keeps being split.

To use it, follow the same demo steps as above, but pass an extra `N` to the
command in step 3:

```
nix run . --  addr_test1vp5cxztpc6hep9ds7fjgmle3l225tk8ske3rmwr9adu0m6qchmx5z 5
```

Then in another terminal, sign 5 snapshots in a row. After the 5th, the
respender prints:

```
Reached max respends (5), stopping.
```

and exits. The address now holds 6 UTxOs: five small ones of `1_000_000`
lovelace each, plus the original UTxO minus `5_000_000` lovelace.

Omit the argument entirely to keep the original behaviour — respend the whole
UTxO forever, with a single output.

If you'd prefer to run the already-compiled binary directly (no Nix), pass the
optional `N` after the address in the same way:

```sh
ucm run.compiled respend-utxo.uc addr_test1vp5cxztpc6hep9ds7fjgmle3l225tk8ske3rmwr9adu0m6qchmx5z 5
```


### via Nix

```
nix run .
```


### Hacking

Create a codebase in this folder like:

```sh
ucm --codebase-create .
```

Then, you can load the transcript into this codebase like:

```sh
ucm transcript.in-place ./transaction-respender.md --codebase .
```

Then you can run:

```sh
ucm -c .
> ls
```

And see the definitions.

Note that, in typical Unison fashion, there is also a `scratch.u`. I have left
in there a function to do the same respending over the HTTP endpoint (much
slower, because we don't wait for Txn confirmations; so it submits failed
Txns.)

Most of the code is now in `respend.u`, so you can hack there as you wish.
