``` ucm :hide
> install.lib @systemfw/concurrent
> install.lib @unison/base
> install.lib @unison/http
> install.lib @unison/json
```

This is a "literate unison" script, that they call a
[transcript](https://www.unison-lang.org/docs/tooling/transcripts/).

It is here because [unison-nix](https://github.com/ceedubs/unison-nix)
requires a transcript file to build a (reprodicble?!) derivation.

> [!Note]
>
> Note that perhaps while this is reproducible, there are no library versions
> pinned here. Nevertheless, the Nix hash in the flake.nix should at least
> indicate if you are getting a different version to me.

## Json busywork

``` unison
greetingsOrSnapshotConfirmed : '{Decoder} (Optional (Either Greetings Snapshot))
greetingsOrSnapshotConfirmed
  = do match at! "tag" text with
      "Greetings"
        -> g = greetingsFromJson ()
           Some << Left <| g

      "SnapshotConfirmed"
        -> e = envelopeFromJson ()
           Some << Right <| snapshot e

      tag -> None


-- Greetings

type Greetings = {
  chainSyncedStatus: Text
}

greetingsFromJson : '{Decoder} Greetings
greetingsFromJson = do
  chainSyncedStatus = at! "chainSyncedStatus" text
  Greetings chainSyncedStatus


-- SnapshotConfirmed Envelope

type Utxo = {
  address: Text,
  value: Nat
}

type Snapshot = {
  number : Nat,
  utxos : Map Text Utxo
}

type Envelope = {
  snapshot : Snapshot
}

use object at!
use Decoder text nat object

envelopeFromJson : '{Decoder} Envelope
envelopeFromJson = do
  snapshot = at! "snapshot" snapshotFromJson
  Envelope snapshot


snapshotFromJson : '{Decoder} Snapshot
snapshotFromJson = do
  number = at! "number" nat
  utxos  = at! "utxo" (object utxoFromJson)
  Snapshot number utxos


utxoFromJson : '{Decoder} Utxo
utxoFromJson = do
  address = at! "address" text
  value   = at! "value" (do at! "lovelace" nat)
  Utxo address value
```

``` ucm
> update
```

## Actual respending logic

``` unison
-- | Actual respend logic using cardano-cli.
computeRespendTx : Text -> Snapshot -> '{IO, Exception} Text
computeRespendTx owningAddress snapshot = do
  (utxoRef, utxo) =
    (filter (cases (id, utxo) -> address utxo == owningAddress) (toList <| utxos snapshot))
      |> head
      |> getOrBug "Couldn't find a UTxO for you"

  txfile = "/tmp/txn-respender-new-tx.json"
  signed = "/tmp/txn-respender-new-tx.signed.json"

  -- 1. Make a new transaction
  e1
    = call "cardano-cli"
        [ "latest", "transaction", "build-raw"
        , "--tx-in"    , utxoRef
        , "--tx-out"   , address utxo ++ "+" ++ (Nat.toText (value utxo))
        , "--fee"      , "0"
        , "--out-file" , txfile
        ]

  -- 2. Sign it
  e2
    = call "cardano-cli"
        ["latest", "transaction", "sign"
        , "--tx-body-file"     , txfile
        , "--signing-key-file" , "key.sk"
        , "--out-file"         , signed
        ]

  -- 3. Return signed contents
  signedTx = readFileUtf8 (FilePath signed)
  signedTx
```

``` ucm
> update
```

## Respend via websocket

``` unison
-- | Upon first observing a snapshot, just continuously re-spend.
ws.respendUtxo : Text -> '{IO, Exception} ()
ws.respendUtxo owningAddress = do
  Random.run do Threads.run do
    wsClient = do
      url = "http://localhost:4001/?history=no"
      ws = HttpRequest.get (URI.parseOrBug url) |> webSocket
      finalizer (_ -> close ws)
      forever do
        receive ws |> cases
          TextMessage t ->
            match Decoder.run greetingsOrSnapshotConfirmed t with
              None -> () -- Skip this message

              -- XXX: Use this to trigger sending an initial respend message.
              Some (Left greetings) ->
                printLine "Saw 'Greetings' ..."

              Some (Right snapshot) ->
                signedTx = computeRespendTx owningAddress snapshot ()
                newTx = "{\"tag\": \"NewTx\", \"transaction\": " ++ signedTx ++ "}"
                send ws (TextMessage newTx)
          BinaryMessage data -> ()
    handle wsClient () with client.HttpWebSocket.handler
```

``` ucm
> update
```

## Entrypoint

``` unison
main = do
  args = getArgs ()
  addr = args |> head |> getOrBug ("Expected exactly one argument: the address that owns the UTxO to respend; got: " ++ toDebugText args)
  printLine "Ready ..."
  ws.respendUtxo addr ()
```

``` ucm
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
