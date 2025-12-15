``` ucm :hide
> install.lib @systemfw/concurrent/releases/7.3.1
> install.lib @unison/base/releases/7.8.3
> install.lib @unison/http/releases/8.0.0
> install.lib @unison/json/releases/1.3.5
```

This is a "literate unison" script, that they call a
[transcript](https://www.unison-lang.org/docs/tooling/transcripts/).

It is here because [unison-nix](https://github.com/ceedubs/unison-nix)
requires a transcript file to build a (reprodicble?!) derivation.

> [!Note]
>
> We have pinned the library versions as best as possible to avoid getting new
> versions that would break the hash.


## Load all code

``` ucm
> load respend.u
> update
```


## Build final binary

``` ucm
> compile main respend-utxo
```

## Running


This part isn't evaluated by ucm/unison; but if you now would like to run the
resulting binary

``` sh
ucm run.compiled respend-utxo.uc addr_test1vp5cxztpc6hep9ds7fjgmle3l225tk8ske3rmwr9adu0m6qchmx5z
```

(Or, via Nix)

``` sh
nix run . --  addr_test1vp5cxztpc6hep9ds7fjgmle3l225tk8ske3rmwr9adu0m6qchmx5z
```
