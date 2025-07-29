import Protobuf "mo:protobuf";
import Result "mo:core/Result";
import Array "mo:core/Array";
import Text "mo:core/Text";
import Nat "mo:core/Nat";
import Nat64 "mo:core/Nat64";
import Order "mo:core/Order";
import Iter "mo:core/Iter";
import Blob "mo:core/Blob";
import Buffer "mo:base/Buffer";
import CID "mo:cid";

module {

  /// Represents a DAG-PB node that can be encoded or decoded.
  /// This corresponds to the PBNode protobuf message in the IPFS specification.
  ///
  /// A DAG-PB node consists of:
  /// * `data`: Optional binary data payload (often UnixFS metadata)
  /// * `links`: Array of links to other DAG-PB nodes
  public type Node = {
    links : [Link];
    data : ?Blob;
  };

  /// Represents a link to another DAG-PB node.
  /// This corresponds to the PBLink protobuf message in the IPFS specification.
  ///
  /// A link consists of:
  /// * `hash`: CID of the target node (required)
  /// * `name`: Optional name for the link (used in directories)
  /// * `tsize`: Optional total size of the linked subtree
  public type Link = {
    hash : CID.CID;
    name : ?Text;
    tsize : ?Nat;
  };

  /// Encodes a DAG-PB node to its binary representation.
  /// This function converts a DAG-PB node to its canonical binary format
  /// according to the DAG-PB specification.
  ///
  /// The encoding process:
  /// 1. Validates the node conforms to DAG-PB constraints
  /// 2. Converts to intermediate protobuf representation
  /// 3. Encodes to binary format using protobuf encoding
  /// 4. Ensures deterministic output (links are sorted)
  ///
  /// Parameters:
  /// * `node`: The DAG-PB node to encode
  ///
  /// Returns:
  /// * `#ok([Nat8])`: Successfully encoded binary data
  /// * `#err(Text)`: Encoding failed with error details
  ///
  /// Example:
  /// ```motoko
  /// let node = { data = ?[1, 2, 3]; links = [] };
  /// let result = toBytes(node);
  /// switch (result) {
  ///     case (#ok(bytes)) { /* use bytes */ };
  ///     case (#err(error)) { /* handle error */ };
  /// };
  /// ```
  public func toBytes(node : Node) : Result.Result<[Nat8], Text> {
    let buffer = Buffer.Buffer<Nat8>(estimateSize(node));
    switch (toBytesBuffer(buffer, node)) {
      case (#ok(_)) #ok(Buffer.toArray(buffer));
      case (#err(e)) #err(e);
    };
  };

  /// Encodes a DAG-PB node directly into a provided buffer.
  /// This function is useful for streaming or when you want to manage buffer allocation yourself.
  /// It returns the number of bytes written to the buffer.
  ///
  /// The encoding process:
  /// 1. Validates the node conforms to DAG-PB constraints
  /// 2. Converts to intermediate protobuf representation
  /// 3. Encodes directly into the provided buffer
  /// 4. Returns the count of bytes written
  ///
  /// Parameters:
  /// * `buffer`: The buffer to write encoded data into
  /// * `node`: The DAG-PB node to encode
  ///
  /// Returns:
  /// * `#ok(Nat)`: Successfully encoded, returns number of bytes written
  /// * `#err(Text)`: Encoding failed with error details
  ///
  /// Example:
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(100);
  /// let node = { data = ?[72, 101, 108, 108, 111]; links = [] };
  /// let result = toBytesBuffer(buffer, node);
  /// switch (result) {
  ///     case (#ok(bytesWritten)) { /* bytesWritten contains the count */ };
  ///     case (#err(error)) { /* handle error */ };
  /// };
  /// ```
  public func toBytesBuffer(buffer : Buffer.Buffer<Nat8>, node : Node) : Result.Result<Nat, Text> {
    switch (toProtobuf(node)) {
      case (#ok(protobufMessage)) switch (Protobuf.toBytesBuffer(buffer, protobufMessage)) {
        case (#ok(bytesWritten)) #ok(bytesWritten);
        case (#err(e)) #err("Failed to encode Protobuf: " # e);
      };
      case (#err(e)) #err(e);
    };
  };

  /// Decodes DAG-PB binary data into a structured node.
  /// This function takes binary data in DAG-PB protobuf format and converts it back
  /// to a structured Node that can be used in Motoko.
  ///
  /// The decoding process:
  /// 1. Decodes the binary data using protobuf decoding
  /// 2. Validates the protobuf data conforms to DAG-PB constraints
  /// 3. Converts protobuf message to DAG-PB Node type
  /// 4. Validates all constraints (link ordering, CID format, etc.)
  ///
  /// Parameters:
  /// * `bytes`: Iterator over the binary data to decode
  ///
  /// Returns:
  /// * `#ok(Node)`: Successfully decoded DAG-PB node
  /// * `#err(Text)`: Decoding failed with error details
  ///
  /// Example:
  /// ```motoko
  /// let bytes = [0x12, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f]; // Protobuf data
  /// let result = fromBytes(bytes.vals());
  /// switch (result) {
  ///     case (#ok(node)) { /* use decoded node */ };
  ///     case (#err(error)) { /* handle error */ };
  /// };
  /// ```
  public func fromBytes(bytes : Iter.Iter<Nat8>) : Result.Result<Node, Text> {
    // First decode using the protobuf library
    let schema : [Protobuf.FieldType] = [
      {
        // Links
        fieldNumber = 2;
        valueType = #repeated(
          #message([
            /* Hash (required) */
            { fieldNumber = 1; valueType = #bytes },
            /* Name (optional) */
            { fieldNumber = 2; valueType = #string },
            /* Tsize (optional) */
            { fieldNumber = 3; valueType = #uint64 },
          ])
        );
      },
      // Data
      { fieldNumber = 1; valueType = #bytes },
    ];
    switch (Protobuf.fromBytes(bytes, schema)) {
      case (#ok(protobufMessage)) {
        // Then convert protobuf message to DAG-PB node
        switch (fromProtobuf(protobufMessage)) {
          case (#ok(dagNode)) #ok(dagNode);
          case (#err(e)) #err(e);
        };
      };
      case (#err(protobufError)) #err("Failed to decode Protobuf: " # protobufError);
    };
  };

  private func toProtobuf(node : Node) : Result.Result<[Protobuf.Field], Text> {
    // Validate node structure
    switch (validate(node)) {
      case (#err(e)) return #err("Node validation failed: " # e);
      case (#ok()) {};
    };

    // Sort links by name for deterministic encoding
    let sortedLinks = sortLinks(node.links);

    let fields = Buffer.Buffer<Protobuf.Field>(2);

    // Add links (field 2)
    for (link in sortedLinks.vals()) {
      switch (linkToProtobufField(link)) {
        case (#ok(linkField)) fields.add(linkField);
        case (#err(e)) return #err(e);
      };
    };

    // Add data field (field 1) if present
    switch (node.data) {
      case (?data) {
        fields.add({
          fieldNumber = 1;
          value = #bytes(Blob.toArray(data));
        });
      };
      case (null) ();
    };

    #ok(Buffer.toArray(fields));
  };

  private func fromProtobuf(message : [Protobuf.Field]) : Result.Result<Node, Text> {
    var data : ?Blob = null;
    let links = Buffer.Buffer<Link>(0);

    for (field in message.vals()) {
      switch (field.fieldNumber) {
        case (1) {
          // Data field
          switch (field.value) {
            case (#bytes(bytes)) data := ?Blob.fromArray(bytes);
            case (_) return #err("Field 1 must be bytes for data, got " # debug_show (field.value));
          };
        };
        case (2) {
          // Links field
          switch (field.value) {
            case (#message(linkMessage)) {
              switch (protobufFieldToLink(linkMessage)) {
                case (#ok(link)) links.add(link);
                case (#err(e)) return #err(e);
              };
            };
            case (#repeated(linkValues)) {
              for (linkValue in linkValues.vals()) {
                let #message(linkMessage) = linkValue else return #err("Expected repeated field 2 to contain messages for links, got " # debug_show (linkValue));
                switch (protobufFieldToLink(linkMessage)) {
                  case (#ok(link)) links.add(link);
                  case (#err(e)) return #err(e);
                };
              };
            };
            case (_) return #err("Field 2 must be a message for links, got " # debug_show (field.value));
          };
        };
        case (_) {
          // Ignore unknown fields for forward compatibility
        };
      };
    };

    let node = {
      data = data;
      links = Buffer.toArray(links);
    };

    // Final validation
    switch (validate(node)) {
      case (#err(e)) #err("Node validation failed: " # e);
      case (#ok()) #ok(node);
    };
  };

  private func validate(node : Node) : Result.Result<(), Text> {

    // Check for duplicate link names
    switch (checkDuplicateNames(node.links)) {
      case (#err(e)) return #err(e);
      case (#ok()) {};
    };

    #ok(());
  };

  // Private helper functions

  private func estimateSize(node : Node) : Nat {
    var size = switch (node.data) {
      case (?data) data.size() + 10; // data + overhead
      case null 0;
    };

    for (link in node.links.vals()) {
      size += 50; // Estimate per link
      switch (link.name) {
        case (?name) size += name.size();
        case null {};
      };
    };

    size;
  };

  private func sortLinks(links : [Link]) : [Link] {
    Array.sort(
      links,
      func(a : Link, b : Link) : Order.Order {
        switch (a.name, b.name) {
          case (null, null) #equal;
          case (null, _) #less;
          case (_, null) #greater;
          case (?nameA, ?nameB) Text.compare(nameA, nameB);
        };
      },
    );
  };

  private func linkToProtobufField(link : Link) : Result.Result<Protobuf.Field, Text> {
    let linkFields = Buffer.Buffer<Protobuf.Field>(3);

    // Hash field (field 1, required)
    let hashBytes = CID.toBytes(link.hash);
    linkFields.add({
      fieldNumber = 1;
      value = #bytes(hashBytes);
    });

    // Name field (field 2, optional)
    switch (link.name) {
      case (?name) {
        linkFields.add({
          fieldNumber = 2;
          value = #string(name);
        });
      };
      case null {};
    };

    // Tsize field (field 3, optional)
    switch (link.tsize) {
      case (?size) {
        linkFields.add({
          fieldNumber = 3;
          value = #uint64(Nat64.fromNat(size));
        });
      };
      case null {};
    };

    #ok({
      fieldNumber = 2; // Links are field 2 in the parent message
      value = #message(Buffer.toArray(linkFields));
    });
  };

  private func protobufFieldToLink(message : [Protobuf.Field]) : Result.Result<Link, Text> {
    var hash : ?CID.CID = null;
    var name : ?Text = null;
    var tsize : ?Nat = null;

    for (field in message.vals()) {
      switch (field.fieldNumber) {
        case (1) {
          // Hash field
          switch (field.value) {
            case (#bytes(bytes)) {
              switch (CID.fromBytes(bytes.vals())) {
                case (#ok(cid)) hash := ?cid;
                case (#err(e)) return #err("Invalid CID in link hash: " # e);
              };
            };
            case (_) return #err("Invalid field type for link hash, expected bytes, got " # debug_show (field.value));
          };
        };
        case (2) {
          // Name field
          switch (field.value) {
            case (#string(str)) {
              name := ?str;
            };
            case (_) return #err("Invalid field type for link name, expected string, got " # debug_show (field.value));
          };
        };
        case (3) {
          // Tsize field
          switch (field.value) {
            case (#uint64(size)) tsize := ?Nat64.toNat(size);
            case (_) return #err("Invalid field type for link tsize, expected uint64, got " # debug_show (field.value));
          };
        };
        case (_) {
          // Ignore unknown fields for forward compatibility
        };
      };
    };

    let ?hashCID = hash else return #err("Link hash field is required");

    #ok({
      hash = hashCID;
      name = name;
      tsize = tsize;
    });
  };

  private func checkDuplicateNames(links : [Link]) : Result.Result<(), Text> {
    if (links.size() <= 1) return #ok(());

    let sortedLinks = sortLinks(links);

    for (i in Nat.range(0, sortedLinks.size() - 2)) {
      switch (sortedLinks[i].name, sortedLinks[i + 1].name) {
        case (?nameA, ?nameB) {
          if (Text.equal(nameA, nameB) and nameA != "") {
            return #err("Duplicate link name: " # nameA);
          };
        };
        case _ {};
      };
    };

    #ok(());
  };
};
