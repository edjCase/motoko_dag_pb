# Motoko DAG-PB

[![MOPS](https://img.shields.io/badge/MOPS-dag--pb-blue)](https://mops.one/dag-pb)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/yourusername/motoko_dag_pb/blob/main/LICENSE)

A Motoko implementation of DAG-PB (DAG-Protobuf) for encoding and decoding IPFS UnixFS data structures with content addressing support.

## Package

### MOPS

```bash
mops add dag-pb
```

To set up MOPS package manager, follow the instructions from the [MOPS Site](https://mops.one)

## What is DAG-PB?

DAG-PB is a protobuf-based format used by IPFS for representing file system data. It's the primary format for UnixFS, enabling content-addressed storage of files and directories. DAG-PB nodes contain data and links to other nodes, forming a directed acyclic graph (DAG).

## Supported Features

- **Deterministic encoding/decoding** of IPFS DAG-PB nodes
- **Content addressing support** with CID (Content Identifier) integration
- **Type-safe node representation** with comprehensive error handling
- **UnixFS compatibility** for file and directory structures
- **Link management** with proper CID handling and name resolution
- **Protobuf compliance** with IPFS DAG-PB specification
- **Streaming support** with buffer-based encoding
- **Full round-trip fidelity** between Motoko types and binary format

## Quick Start

### Example 1: Basic Node Creation and Encoding

```motoko
import DagPb "mo:dag-pb";
import CID "mo:cid";
import Runetime "mo:core/Runetime";

// Create a simple DAG-PB node with data
let node : DagPb.Node = {
    data = ?[72, 101, 108, 108, 111]; // "Hello" in bytes
    links = [];
};

// Encode to bytes
let bytes: [Nat8] = switch (DagPb.toBytes(node)) {
    case (#err(error)) Runetime.trap("Encoding failed: " # debug_show(error));
    case (#ok(bytes)) bytes;
};

// Decode back to node
let dagNode : DagPb.Node = switch (DagPb.fromBytes(bytes.vals())) {
    case (#err(error)) Runetime.trap("Decoding failed: " # debug_show(error));
    case (#ok(node)) node;
};
```

### Example 2: Directory Structure with Links

```motoko
import DagPb "mo:dag-pb";
import CID "mo:cid";

// Create links to files
let fileLink1 : DagPb.Link = {
    hash = someCID1;
    name = ?"file1.txt";
    tsize = ?1024;
};

let fileLink2 : DagPb.Link = {
    hash = someCID2;
    name = ?"file2.txt";
    tsize = ?2048;
};

// Create directory node
let dirNode : DagPb.Node = {
    data = ?unixfsDirectoryHeader; // UnixFS directory metadata
    links = [fileLink1, fileLink2];
};
```

### Example 3: Buffer-based Encoding

```motoko
import DagPb "mo:dag-pb";
import Buffer "mo:base/Buffer";

let node : DagPb.Node = {
    data = ?[1, 2, 3, 4];
    links = [];
};

// Create buffer for streaming encoding
let buffer = Buffer.Buffer<Nat8>(100);

// Encode to buffer and get bytes written count
let bytesWritten: Nat = switch (DagPb.toBytesBuffer(buffer, node)) {
    case (#err(error)) Debug.trap("Encoding failed: " # debug_show(error));
    case (#ok(count)) count;
};

// Buffer now contains the encoded protobuf data
let encodedBytes = Buffer.toArray(buffer);
```

## API Reference

### Main Functions

- **`toBytes()`** - Converts DAG-PB nodes to binary protobuf format
- **`fromBytes()`** - Converts binary protobuf data back to DAG-PB nodes
- **`toBytesBuffer()`** - Streams encoding to a buffer and returns bytes written count
- **`validate()`** - Validates node structure and constraints

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

// DAG-PB specific encoding errors
public type DagPbEncodingError = {
    #invalidNode : Text;           // Node structure is invalid
    #invalidLink : Text;           // Link structure is invalid
    #protobufEncodingError : Text; // Protobuf encoding failed
    #cidEncodingError : Text;      // CID encoding failed
};

// DAG-PB specific decoding errors
public type DagPbDecodingError = {
    #invalidProtobuf : Text;       // Invalid protobuf structure
    #invalidCID : Text;            // Malformed CID in link
    #invalidNodeStructure : Text;  // Node doesn't match DAG-PB spec
    #protobufDecodingError : Text; // Protobuf decoding failed
    #missingRequiredField : Text;  // Required protobuf field missing
};
```

### Functions

```motoko
// Encode a DAG-PB node to bytes
public func toBytes(node : Node) : Result.Result<[Nat8], DagPbEncodingError>;

// Encode a DAG-PB node to an existing buffer (returns bytes written count)
public func toBytesBuffer(buffer : Buffer.Buffer<Nat8>, node : Node) : Result.Result<Nat, DagPbEncodingError>;

// Decode bytes to a DAG-PB node
public func fromBytes(bytes : Iter.Iter<Nat8>) : Result.Result<Node, DagPbDecodingError>;

// Validate a DAG-PB node structure
public func validate(node : Node) : Result.Result<(), Text>;

// Calculate the cumulative size of a node and its links
public func cumulativeSize(node : Node) : Nat;

// Get all CIDs referenced by a node
public func getLinks(node : Node) : [CID.CID];
```

## DAG-PB Specification

This implementation follows the official IPFS DAG-PB specification:

### Protobuf Schema

```protobuf
message PBNode {
  repeated PBLink Links = 2;
  optional bytes Data = 1;
}

message PBLink {
  optional bytes Hash = 1;
  optional string Name = 2;
  optional uint64 Tsize = 3;
}
```

### Key Rules

1. **Links are ordered**: Links must be sorted by name for deterministic encoding
2. **Hash field**: Must be a valid multihash (raw bytes, not CID)
3. **Tsize field**: Represents total size of linked subtree (optional)
4. **Data field**: Optional raw bytes payload
5. **Name constraints**: Link names must be valid UTF-8 if present

## UnixFS Integration

DAG-PB is primarily used with UnixFS for file system structures:

```motoko
// File node
let fileNode = {
    data = ?unixfsFileHeader;
    links = []; // Files have no links
};

// Directory node
let dirNode = {
    data = ?unixfsDirectoryHeader;
    links = [
        { hash = fileCID; name = ?"readme.txt"; tsize = ?1024 },
        { hash = subdirCID; name = ?"subdir"; tsize = ?4096 }
    ];
};

// Large file with multiple blocks
let largeFileNode = {
    data = ?unixfsFileHeader;
    links = [
        { hash = block1CID; name = null; tsize = ?262144 },
        { hash = block2CID; name = null; tsize = ?262144 },
        { hash = block3CID; name = null; tsize = ?131072 }
    ];
};
```

## Performance Considerations

- **Memory usage**: Large nodes with many links consume more memory
- **Encoding efficiency**: Protobuf encoding is compact and efficient
- **Validation overhead**: Link sorting and validation add processing time
- **Streaming support**: Use `toBytesBuffer()` for memory-efficient encoding

## Compatibility

- **IPFS compatible**: Produces nodes compatible with go-ipfs and js-ipfs
- **Deterministic**: Same logical node always produces identical bytes
- **Standards compliant**: Follows official DAG-PB and protobuf specifications

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
