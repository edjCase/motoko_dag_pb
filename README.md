# Motoko DAG-PB

[![MOPS](https://img.shields.io/badge/MOPS-dag--pb-blue)](https://mops.one/dag-pb)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/yourusername/motoko_dag_pb/blob/main/LICENSE)

A Motoko implementation of DAG-PB (DAG-Protobuf) for encoding and decoding IPLD data structures with content addressing support.

## Package

### MOPS

```bash
mops add dag-pb
```

To set up MOPS package manager, follow the instructions from the [MOPS Site](https://mops.one)

## What is DAG-PB?

DAG-PB is a protobuf-based format used by IPFS for representing file system data. It's the primary format for UnixFS, enabling content-addressed storage of files and directories. DAG-PB nodes contain data and links to other nodes, forming a directed acyclic graph (DAG).

## Quick Start

### Example 1: Basic Encoding

```motoko
import DagPb "mo:dag-pb";
import CID "mo:cid";
import Runetime "mo:core/Runetime";

// Create a simple DAG-PB node with data
let node : DagPb.Node = {
   links = [
       {
           hash = bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi;
           name = ?"config.json";
           tsize = ?256;
       },
       {
           hash = bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku;
           name = ?"data.csv";
           tsize = ?4096;
       }
   ];
   data = null; // Optional Blob data
};

// Encode to bytes
let bytes: [Nat8] = switch (DagPb.toBytes(node)) {
    case (#err(error)) Runetime.trap("Encoding failed: " # debug_show(error));
    case (#ok(bytes)) bytes;
};
```

### Example 2: Basic Decoding

```motoko
import DagPb "mo:dag-pb";
import CID "mo:cid";

let bytes : Blob = "..."; // DAG-PB bytes

// Decode to node
let dagNode : DagPb.Node = switch (DagPb.fromBytes(bytes.vals())) {
    case (#err(error)) Runetime.trap("Decoding failed: " # debug_show(error));
    case (#ok(node)) node;
};
```

### Example 3: Buffer-based Encoding

```motoko
import DagPb "mo:dag-pb";
import Buffer "mo:buffer";
import List "mo:core/List";

let node : DagPb.Node = ...;

// Create buffer for streaming encoding
let list = List.empty<Nat8>();

// Encode to buffer and get bytes written count
let bytesWritten: Nat = switch (DagPb.toBytesBuffer(Buffer.fromList<Nat8>(list), node)) {
    case (#err(error)) Debug.trap("Encoding failed: " # debug_show(error));
    case (#ok(count)) count;
};

// Buffer now contains the encoded protobuf data
let encodedBytes = List.toArray(list);
```

## API Reference

### Main Functions

- **`toBytes()`** - Converts DAG-PB nodes to binary protobuf format
- **`fromBytes()`** - Converts binary protobuf data back to DAG-PB nodes
- **`toBytesBuffer()`** - Streams encoding to a buffer and returns bytes written count

### Types

```motoko
// Main node type representing a DAG-PB node
public type Node = {
    data : ?[Nat8];    // Optional raw data payload
    links : [Link];    // Array of links to other nodes
};

// Link to another DAG-PB node
public type Link = {
    hash : CID.CID;    // CID of the linked node
    name : ?Text;      // Optional name for the link
    tsize : ?Nat;      // Optional total size of linked subtree
};
```

### Functions

```motoko
// Encode a DAG-PB node to bytes
public func toBytes(node : Node) : Result.Result<[Nat8], Text>;

// Encode a DAG-PB node to an existing buffer (returns bytes written count)
public func toBytesBuffer(buffer : Buffer.Buffer<Nat8>, node : Node) : Result.Result<Nat, Text>;

// Decode bytes to a DAG-PB node
public func fromBytes(bytes : Iter.Iter<Nat8>) : Result.Result<Node, Text>;
```

## DAG-PB Specification

This implementation follows the official IPFS DAG-PB specification:
[https://ipld.io/specs/codecs/dag-pb/spec/](https://ipld.io/specs/codecs/dag-pb/spec/)

### Protobuf Schema

```protobuf
message PBLink {
  // binary CID (with no multibase prefix) of the target object
  optional bytes Hash = 1;

  // UTF-8 string name
  optional string Name = 2;

  // cumulative size of target object
  optional uint64 Tsize = 3;
}

message PBNode {
  // refs to other objects
  repeated PBLink Links = 2;

  // opaque user data
  optional bytes Data = 1;
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
