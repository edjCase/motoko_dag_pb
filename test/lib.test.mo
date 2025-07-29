import { test } "mo:test";
import Debug "mo:core/Debug";
import DagPb "../src";
import List "mo:core/List";
import Text "mo:core/Text";
import Blob "mo:core/Blob";
import Runtime "mo:core/Runtime";

test(
  "to/fromBytes",
  func() {
    type TestCase = {
      node : DagPb.Node;
      expectedBytes : Blob;
    };
    let testCases : [TestCase] = [{
      node = {
        data = null;
        links = [];
      };
      expectedBytes = "";
    }];

    let failures = List.empty<Text>();
    label f for (testCase in testCases.vals()) {
      let actualBytes = switch (DagPb.toBytes(testCase.node)) {
        case (#ok(bytes)) Blob.fromArray(bytes);
        case (#err(error)) Runtime.trap("Failed to serialize node: " # error);
      };
      if (actualBytes != testCase.expectedBytes) {
        let message = "toBytes failed:\n Expected " # debug_show (testCase.expectedBytes) # "\nActual:   " # debug_show (actualBytes) # "\nNode:     " # debug_show (testCase.node);
        List.add(failures, message);
        continue f;
      };
      let parsedNode = switch (DagPb.fromBytes(actualBytes.vals())) {
        case (#ok(node)) node;
        case (#err(error)) Runtime.trap("Failed to deserialize node: " # error);
      };
      if (parsedNode != testCase.node) {
        let message = "fromBytes failed:\n Expected " # debug_show (testCase.node) # "\nActual:   " # debug_show (parsedNode) # "\nBytes:   " # debug_show (actualBytes);
        List.add(failures, message);
      };
    };
    if (List.size(failures) > 0) {
      let errorMessage = Text.join("\n---\n", List.values(failures));
      Runtime.trap(errorMessage);
    };
  },
);
