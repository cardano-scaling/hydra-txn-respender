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

> [!Note]
>
> At present, you will need to change the address in
> `transaction-respender.md` if you wish to run it in a different envrionment.



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


### Todo

- [x] Keep both HTTP and WebSocket options
- [x] Show how to use with `nix run .#demo`
- [x] Unison dependencies
- [x] Configuration of arguments
