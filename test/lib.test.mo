import { test } "mo:test";
import DagPb "../src";
import List "mo:core/List";
import Text "mo:core/Text";
import Blob "mo:core/Blob";
import Runtime "mo:core/Runtime";
import CID "mo:cid";
import Sha256 "mo:sha2/Sha256";

func cidFromTextOrTrap(text : Text) : CID.CID {
  switch (CID.fromText(text)) {
    case (#ok(cid)) return cid;
    case (#err(e)) Runtime.trap("Invalid CID: " # e);
  };
};

test(
  "to/fromBytes",
  func() {
    type TestCase = {
      node : DagPb.Node;
      expectedBytes : Blob;
      expectedCID : CID.CID;
    };
    let testCases : [TestCase] = [
      // dagpb_empty
      {
        node = {
          data = null;
          links = [];
        };
        expectedBytes = "";
        expectedCID = cidFromTextOrTrap("bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku");
      },
      // dagpb_Data_zero
      {
        node = {
          data = ?"";
          links = [];
        };
        expectedBytes = "\0a\00";
        expectedCID = cidFromTextOrTrap("bafybeiaqfni3s5s2k2r6rgpxz4hohdsskh44ka5tk6ztbjerqpvxwfkwaq");
      },
      // dagpb_Data_some
      {
        node = {
          data = ?"\00\01\02\03\04";
          links = [];
        };
        expectedBytes = "\0a\05\00\01\02\03\04";
        expectedCID = cidFromTextOrTrap("bafybeibazl2z4vqp2tmwcfag6wirmtpnomxknqcgrauj7m2yisrz3qjbom");
      },
      // dagpb_Links_Hash_some
      {
        node = {
          data = null;
          links = [{
            hash = #v1({
              codec = #raw;
              hash = "\00\01\02\03\04";
              hashAlgorithm = #none;
            });
            name = null;
            tsize = null;
          }];
        };
        expectedBytes = "\12\0b\0a\09\01\55\00\05\00\01\02\03\04";
        expectedCID = cidFromTextOrTrap("bafybeia53f5n75ituvc3yupuf7tdnxf6fqetrmo2alc6g6iljkmk7ys5mm");
      },
      // dagpb_Links_Hash_some_Name_zero
      {
        node = {
          data = null;
          links = [{
            hash = #v1({
              codec = #raw;
              hash = "\00\01\02\03\04";
              hashAlgorithm = #none;
            });
            name = ?"";
            tsize = null;
          }];
        };
        expectedBytes = "\12\0d\0a\09\01\55\00\05\00\01\02\03\04\12\00";
        expectedCID = cidFromTextOrTrap("bafybeie7fstnkm4yshfwnmpp7d3mlh4f4okmk7a54d6c3ffr755q7qzk44");
      },
      // dagpb_Links_Hash_some_Name_some
      {
        node = {
          data = null;
          links = [{
            hash = #v1({
              codec = #raw;
              hash = "\00\01\02\03\04";
              hashAlgorithm = #none;
            });
            name = ?"some name";
            tsize = null;
          }];
        };
        expectedBytes = "\12\16\0a\09\01\55\00\05\00\01\02\03\04\12\09\73\6f\6d\65\20\6e\61\6d\65";
        expectedCID = cidFromTextOrTrap("bafybeifq4hcxma3kjljrpxtunnljtc6tvbkgsy3vldyfpfbx2lij76niyu");
      },
      // dagpb_Links_Hash_some_Tsize_zero
      {
        node = {
          data = null;
          links = [{
            hash = #v1({
              codec = #raw;
              hash = "\00\01\02\03\04";
              hashAlgorithm = #none;
            });
            name = null;
            tsize = ?0;
          }];
        };
        expectedBytes = "\12\0d\0a\09\01\55\00\05\00\01\02\03\04\18\00";
        expectedCID = cidFromTextOrTrap("bafybeichjs5otecmbvwh5azdr4jc45mp2qcofh2fr54wjdxhz4znahod2i");
      },
      // dagpb_Links_Hash_some_Tsize_some
      {
        node = {
          data = null;
          links = [{
            hash = #v1({
              codec = #raw;
              hash = "\00\01\02\03\04";
              hashAlgorithm = #none;
            });
            name = null;
            tsize = ?9_007_199_254_740_991;
          }];
        };
        expectedBytes = "\12\14\0a\09\01\55\00\05\00\01\02\03\04\18\ff\ff\ff\ff\ff\ff\ff\0f";
        expectedCID = cidFromTextOrTrap("bafybeiezymjvhwfuharanxmzxwuomzjjuzqjewjolr4phaiyp6l7qfwo64");
      },
      // dagpb_1link
      {
        node = {
          data = null;
          links = [{
            hash = #v0({
              hash = "\75\21\FE\19\C3\74\A9\77\59\22\6D\C5\C0\C8\E6\74\E7\39\50\E8\1B\21\1F\7D\D3\B6\B3\08\83\A0\8A\51";
            });
            name = null;
            tsize = null;
          }];
        };
        expectedBytes = "\12\24\0a\22\12\20\75\21\fe\19\c3\74\a9\77\59\22\6d\c5\c0\c8\e6\74\e7\39\50\e8\1b\21\1f\7d\d3\b6\b3\08\83\a0\8a\51";
        expectedCID = cidFromTextOrTrap("bafybeihyivpglm6o6wrafbe36fp5l67abmewk7i2eob5wacdbhz7as5obe");
      },
      // dagpb_2link+data
      {
        node = {
          data = ?"\73\6F\6D\65\20\64\61\74\61";
          links = [
            {
              hash = #v0({
                hash = "\8A\B7\A6\C5\E7\47\37\87\8A\C7\38\63\CB\76\73\9D\15\D4\66\6D\E4\4E\57\56\BF\55\A2\F9\E9\AB\5F\43";
              });
              name = ?"some link";
              tsize = ?100_000_000;
            },
            {
              hash = #v0({
                hash = "\8A\B7\A6\C5\E7\47\37\87\8A\C7\38\63\CB\76\73\9D\15\D4\66\6D\E4\4E\57\56\BF\55\A2\F9\E9\AB\5F\44";
              });
              name = ?"some other link";
              tsize = ?8;
            },
          ];
        };
        expectedBytes = "\12\34\0a\22\12\20\8a\b7\a6\c5\e7\47\37\87\8a\c7\38\63\cb\76\73\9d\15\d4\66\6d\e4\4e\57\56\bf\55\a2\f9\e9\ab\5f\43\12\09\73\6f\6d\65\20\6c\69\6e\6b\18\80\c2\d7\2f\12\37\0a\22\12\20\8a\b7\a6\c5\e7\47\37\87\8a\c7\38\63\cb\76\73\9d\15\d4\66\6d\e4\4e\57\56\bf\55\a2\f9\e9\ab\5f\44\12\0f\73\6f\6d\65\20\6f\74\68\65\72\20\6c\69\6e\6b\18\08\0a\09\73\6f\6d\65\20\64\61\74\61";
        expectedCID = cidFromTextOrTrap("bafybeibh647pmxyksmdm24uad6b5f7tx4dhvilzbg2fiqgzll4yek7g7y4");
      },
      // dagpb_simple_forms_1
      {
        node = {
          data = ?"\01\02\03";
          links = [];
        };
        expectedBytes = "\0a\03\01\02\03";
        expectedCID = cidFromTextOrTrap("bafybeia2qk4u55f2qj7zimmtpulejgz7urp7rzs44cvledcaj42gltkk3u");
      },
      // dagpb_simple_forms_2
      {
        node = {
          data = null;
          links = [
            {
              hash = #v1({
                codec = #raw;
                hash = "\00\01\02\03\04";
                hashAlgorithm = #none;
              });
              name = null;
              tsize = null;
            },
            {
              hash = #v1({
                codec = #raw;
                hash = "\00\01\02\03\04";
                hashAlgorithm = #none;
              });
              name = ?"bar";
              tsize = null;
            },
            {
              hash = #v1({
                codec = #raw;
                hash = "\00\01\02\03\04";
                hashAlgorithm = #none;
              });
              name = ?"foo";
              tsize = null;
            },
          ];
        };
        expectedBytes = "\12\0b\0a\09\01\55\00\05\00\01\02\03\04\12\10\0a\09\01\55\00\05\00\01\02\03\04\12\03\62\61\72\12\10\0a\09\01\55\00\05\00\01\02\03\04\12\03\66\6f\6f";
        expectedCID = cidFromTextOrTrap("bafybeiahfgovhod2uvww72vwdgatl5r6qkoeegg7at2bghiokupfphqcku");
      },
      // dagpb_simple_forms_3
      {
        node = {
          data = null;
          links = [
            {
              hash = #v1({
                codec = #raw;
                hash = "\00\01\02\03\04";
                hashAlgorithm = #none;
              });
              name = null;
              tsize = null;
            },
            {
              hash = #v1({
                codec = #raw;
                hash = "\00\01\02\03\04";
                hashAlgorithm = #none;
              });
              name = ?"a";
              tsize = null;
            },
            {
              hash = #v1({
                codec = #raw;
                hash = "\00\01\02\03\04";
                hashAlgorithm = #none;
              });
              name = ?"a";
              tsize = null;
            },
          ];
        };
        expectedBytes = "\12\0b\0a\09\01\55\00\05\00\01\02\03\04\12\0e\0a\09\01\55\00\05\00\01\02\03\04\12\01\61\12\0e\0a\09\01\55\00\05\00\01\02\03\04\12\01\61";
        expectedCID = cidFromTextOrTrap("bafybeidrg2f6slbv4yzydqtgmsi2vzojajnt7iufcreynfpxndca4z5twm");
      },
      // dagpb_simple_forms_4
      {
        node = {
          data = null;
          links = [
            {
              hash = #v1({
                codec = #raw;
                hash = "\00\01\02\03\04";
                hashAlgorithm = #none;
              });
              name = ?"a";
              tsize = null;
            },
            {
              hash = #v1({
                codec = #raw;
                hash = "\00\01\02\03\04";
                hashAlgorithm = #none;
              });
              name = ?"a";
              tsize = null;
            },
          ];
        };
        expectedBytes = "\12\0e\0a\09\01\55\00\05\00\01\02\03\04\12\01\61\12\0e\0a\09\01\55\00\05\00\01\02\03\04\12\01\61";
        expectedCID = cidFromTextOrTrap("bafybeieube7zxmzoc5bgttub2aqofi6xdzimv5munkjseeqccn36a6v6j4");
      },
      // dagpb_4namedlinks+data
      {
        node = {
          data = ?"\08\01";
          links = [
            {
              hash = #v0({
                hash = "\B4\39\7C\02\DA\55\13\56\3D\33\EE\F8\94\BF\68\F2\CC\DF\1B\DF\C1\4A\97\69\56\AB\3D\1C\72\F7\35\A0";
              });
              name = ?"audio_only.m4a";
              tsize = ?23_319_629;
            },
            {
              hash = #v0({
                hash = "\02\5C\13\FC\D1\A8\85\DF\44\4F\64\A4\A8\2A\26\AE\A8\67\B1\14\8C\68\CB\67\1E\83\58\9F\97\11\49\32";
              });
              name = ?"chat.txt";
              tsize = ?996;
            },
            {
              hash = #v0({
                hash = "\5D\44\A3\05\B9\B3\28\AB\80\45\1D\0D\AA\72\A1\2A\7B\F2\76\3C\5F\8B\BE\32\75\97\A3\1E\E4\0D\1E\48";
              });
              name = ?"playback.m3u";
              tsize = ?116;
            },
            {
              hash = #v0({
                hash = "\25\39\ED\6E\85\F2\A6\F9\09\7D\B9\D7\6C\FF\D4\9B\F3\04\2E\B2\E3\E8\E9\AF\4A\3C\E8\42\D4\9D\EA\22";
              });
              name = ?"zoom_0.mp4";
              tsize = ?306_281_879;
            },
          ];
        };
        expectedBytes = "\12\39\0a\22\12\20\b4\39\7c\02\da\55\13\56\3d\33\ee\f8\94\bf\68\f2\cc\df\1b\df\c1\4a\97\69\56\ab\3d\1c\72\f7\35\a0\12\0e\61\75\64\69\6f\5f\6f\6e\6c\79\2e\6d\34\61\18\cd\a8\8f\0b\12\31\0a\22\12\20\02\5c\13\fc\d1\a8\85\df\44\4f\64\a4\a8\2a\26\ae\a8\67\b1\14\8c\68\cb\67\1e\83\58\9f\97\11\49\32\12\08\63\68\61\74\2e\74\78\74\18\e4\07\12\34\0a\22\12\20\5d\44\a3\05\b9\b3\28\ab\80\45\1d\0d\aa\72\a1\2a\7b\f2\76\3c\5f\8b\be\32\75\97\a3\1e\e4\0d\1e\48\12\0c\70\6c\61\79\62\61\63\6b\2e\6d\33\75\18\74\12\36\0a\22\12\20\25\39\ed\6e\85\f2\a6\f9\09\7d\b9\d7\6c\ff\d4\9b\f3\04\2e\b2\e3\e8\e9\af\4a\3c\e8\42\d4\9d\ea\22\12\0a\7a\6f\6f\6d\5f\30\2e\6d\70\34\18\97\fb\85\92\01\0a\02\08\01";
        expectedCID = cidFromTextOrTrap("bafybeigcsevw74ssldzfwhiijzmg7a35lssfmjkuoj2t5qs5u5aztj47tq");
      },
      // dagpb_7unnamedlinks+data
      {
        node = {
          data = ?"\08\02\18\CB\C1\81\92\01\20\80\80\E0\15\20\80\80\E0\15\20\80\80\E0\15\20\80\80\E0\15\20\80\80\E0\15\20\80\80\E0\15\20\CB\C1\C1\0F";
          links = [
            {
              hash = #v0({
                hash = "\3F\29\08\6B\59\B9\E0\46\B3\62\B4\B1\9C\93\71\E8\34\A9\F5\A8\05\97\AF\83\BE\6D\8B\7D\1A\5A\D3\3B";
              });
              name = ?"";
              tsize = ?45_623_854;
            },
            {
              hash = #v0({
                hash = "\AE\1A\5A\FD\7C\77\05\07\DD\DF\17\F9\2B\BA\7A\32\69\74\AF\8A\E5\27\7C\19\8C\F1\32\06\37\3F\72\63";
              });
              name = ?"";
              tsize = ?45_623_854;
            },
            {
              hash = #v0({
                hash = "\22\AB\2E\BF\9C\35\23\07\7B\D6\A1\71\D5\16\EA\0E\1B\E1\BE\B1\32\D8\53\77\8B\CC\62\CD\20\8E\77\F1";
              });
              name = ?"";
              tsize = ?45_623_854;
            },
            {
              hash = #v0({
                hash = "\40\A7\7F\E7\BC\69\BB\EF\24\91\F7\63\3B\7C\46\2D\0B\CE\96\88\68\F8\8E\2C\BC\AA\E9\D0\99\69\97\E8";
              });
              name = ?"";
              tsize = ?45_623_854;
            },
            {
              hash = #v0({
                hash = "\6A\E1\97\9B\14\DD\43\96\6B\02\41\EB\E8\0A\C2\A0\4A\D4\89\59\07\8D\C5\AF\FA\12\86\06\48\35\6E\F6";
              });
              name = ?"";
              tsize = ?45_623_854;
            },
            {
              hash = #v0({
                hash = "\A9\57\D1\F8\9E\B9\A8\61\59\3B\FC\D1\9E\06\37\B5\C9\57\69\94\17\E2\B7\F2\3C\88\65\3A\24\08\36\C4";
              });
              name = ?"";
              tsize = ?45_623_854;
            },
            {
              hash = #v0({
                hash = "\34\5F\9C\21\37\A2\CD\76\D7\B8\76\AF\4B\FE\CD\01\F8\0B\7D\D1\25\F3\75\CB\0D\56\F8\A2\F9\6D\E2\C3";
              });
              name = ?"";
              tsize = ?32_538_395;
            },
          ];
        };
        expectedBytes = "\12\2b\0a\22\12\20\3f\29\08\6b\59\b9\e0\46\b3\62\b4\b1\9c\93\71\e8\34\a9\f5\a8\05\97\af\83\be\6d\8b\7d\1a\5a\d3\3b\12\00\18\ae\d4\e0\15\12\2b\0a\22\12\20\ae\1a\5a\fd\7c\77\05\07\dd\df\17\f9\2b\ba\7a\32\69\74\af\8a\e5\27\7c\19\8c\f1\32\06\37\3f\72\63\12\00\18\ae\d4\e0\15\12\2b\0a\22\12\20\22\ab\2e\bf\9c\35\23\07\7b\d6\a1\71\d5\16\ea\0e\1b\e1\be\b1\32\d8\53\77\8b\cc\62\cd\20\8e\77\f1\12\00\18\ae\d4\e0\15\12\2b\0a\22\12\20\40\a7\7f\e7\bc\69\bb\ef\24\91\f7\63\3b\7c\46\2d\0b\ce\96\88\68\f8\8e\2c\bc\aa\e9\d0\99\69\97\e8\12\00\18\ae\d4\e0\15\12\2b\0a\22\12\20\6a\e1\97\9b\14\dd\43\96\6b\02\41\eb\e8\0a\c2\a0\4a\d4\89\59\07\8d\c5\af\fa\12\86\06\48\35\6e\f6\12\00\18\ae\d4\e0\15\12\2b\0a\22\12\20\a9\57\d1\f8\9e\b9\a8\61\59\3b\fc\d1\9e\06\37\b5\c9\57\69\94\17\e2\b7\f2\3c\88\65\3a\24\08\36\c4\12\00\18\ae\d4\e0\15\12\2b\0a\22\12\20\34\5f\9c\21\37\a2\cd\76\d7\b8\76\af\4b\fe\cd\01\f8\0b\7d\d1\25\f3\75\cb\0d\56\f8\a2\f9\6d\e2\c3\12\00\18\9b\fe\c1\0f\0a\2b\08\02\18\cb\c1\81\92\01\20\80\80\e0\15\20\80\80\e0\15\20\80\80\e0\15\20\80\80\e0\15\20\80\80\e0\15\20\80\80\e0\15\20\cb\c1\c1\0f";
        expectedCID = cidFromTextOrTrap("bafybeibfhhww5bpsu34qs7nz25wp7ve36mcc5mxd5du26sr45bbnjhpkei");
      },
      // dagpb_11unnamedlinks+data
      {
        node = {
          data = ?"\73\6F\6D\65\20\64\61\74\61";
          links = [
            {
              hash = #v0({
                hash = "\58\22\D1\87\BD\40\B0\4C\C8\AE\74\37\88\8E\BF\84\4E\FA\C1\72\9E\09\8C\88\16\D5\85\D0\FC\C4\2B\5B";
              });
              name = ?"";
              tsize = ?262_158;
            },
            {
              hash = #v0({
                hash = "\0B\79\BA\DE\E1\0D\C3\F7\78\1A\7A\9D\0F\02\0C\C0\F7\10\B3\28\C4\97\5C\2D\BC\30\A1\70\CD\18\8E\2C";
              });
              name = ?"";
              tsize = ?262_158;
            },
            {
              hash = #v0({
                hash = "\22\AD\63\1C\69\EE\98\30\95\B5\B8\AC\D0\29\FF\94\AF\F1\DC\6C\48\83\78\78\58\9A\92\B9\0D\FE\A3\17";
              });
              name = ?"";
              tsize = ?262_158;
            },
            {
              hash = #v0({
                hash = "\DF\7F\D0\8C\47\84\FE\69\38\C6\40\DF\47\36\46\E4\F1\6C\7D\0C\65\67\AB\79\EC\69\81\76\7F\C3\F0\1A";
              });
              name = ?"";
              tsize = ?262_158;
            },
            {
              hash = #v0({
                hash = "\00\88\8C\81\5A\D7\D0\55\37\7B\DB\7B\77\79\FC\97\40\E5\48\CB\5D\AC\90\C7\1B\9A\F9\F5\1A\87\9C\2D";
              });
              name = ?"";
              tsize = ?262_158;
            },
            {
              hash = #v0({
                hash = "\76\6D\B3\72\D0\15\C5\C7\00\F5\38\33\65\56\37\01\65\C8\89\33\47\91\48\7A\5E\48\D6\08\0F\1C\99\EA";
              });
              name = ?"";
              tsize = ?262_158;
            },
            {
              hash = #v0({
                hash = "\2F\53\30\04\CE\ED\74\27\9B\32\C5\8E\B0\E3\D2\A2\3B\C2\7B\A1\4A\B0\72\98\40\6C\42\BA\B8\D5\43\21";
              });
              name = ?"";
              tsize = ?262_158;
            },
            {
              hash = #v0({
                hash = "\4C\50\CF\DE\FA\02\09\76\6F\88\59\19\AC\8F\FC\25\8E\92\53\C3\00\1A\C2\38\14\F8\75\D4\14\D3\94\73";
              });
              name = ?"";
              tsize = ?262_158;
            },
            {
              hash = #v0({
                hash = "\00\89\46\11\DF\A1\92\85\30\20\CB\BA\DE\1A\9A\0A\3F\35\9D\26\E0\D3\8C\AF\4D\72\B9\B3\06\FF\5A\0B";
              });
              name = ?"";
              tsize = ?262_158;
            },
            {
              hash = #v0({
                hash = "\73\0D\DB\A8\3E\31\47\BB\E1\07\80\B9\7F\F0\71\8C\74\C3\60\37\B9\7B\3B\79\B4\5C\45\11\80\65\45\81";
              });
              name = ?"";
              tsize = ?262_158;
            },
            {
              hash = #v0({
                hash = "\48\EA\9D\5D\42\3F\67\8D\83\D5\59\D2\34\9B\E8\32\55\27\29\0B\07\0C\90\FC\1A\CD\96\8F\0B\F7\0A\06";
              });
              name = ?"";
              tsize = ?262_158;
            },
          ];
        };
        expectedBytes = "\12\2a\0a\22\12\20\58\22\d1\87\bd\40\b0\4c\c8\ae\74\37\88\8e\bf\84\4e\fa\c1\72\9e\09\8c\88\16\d5\85\d0\fc\c4\2b\5b\12\00\18\8e\80\10\12\2a\0a\22\12\20\0b\79\ba\de\e1\0d\c3\f7\78\1a\7a\9d\0f\02\0c\c0\f7\10\b3\28\c4\97\5c\2d\bc\30\a1\70\cd\18\8e\2c\12\00\18\8e\80\10\12\2a\0a\22\12\20\22\ad\63\1c\69\ee\98\30\95\b5\b8\ac\d0\29\ff\94\af\f1\dc\6c\48\83\78\78\58\9a\92\b9\0d\fe\a3\17\12\00\18\8e\80\10\12\2a\0a\22\12\20\df\7f\d0\8c\47\84\fe\69\38\c6\40\df\47\36\46\e4\f1\6c\7d\0c\65\67\ab\79\ec\69\81\76\7f\c3\f0\1a\12\00\18\8e\80\10\12\2a\0a\22\12\20\00\88\8c\81\5a\d7\d0\55\37\7b\db\7b\77\79\fc\97\40\e5\48\cb\5d\ac\90\c7\1b\9a\f9\f5\1a\87\9c\2d\12\00\18\8e\80\10\12\2a\0a\22\12\20\76\6d\b3\72\d0\15\c5\c7\00\f5\38\33\65\56\37\01\65\c8\89\33\47\91\48\7a\5e\48\d6\08\0f\1c\99\ea\12\00\18\8e\80\10\12\2a\0a\22\12\20\2f\53\30\04\ce\ed\74\27\9b\32\c5\8e\b0\e3\d2\a2\3b\c2\7b\a1\4a\b0\72\98\40\6c\42\ba\b8\d5\43\21\12\00\18\8e\80\10\12\2a\0a\22\12\20\4c\50\cf\de\fa\02\09\76\6f\88\59\19\ac\8f\fc\25\8e\92\53\c3\00\1a\c2\38\14\f8\75\d4\14\d3\94\73\12\00\18\8e\80\10\12\2a\0a\22\12\20\00\89\46\11\df\a1\92\85\30\20\cb\ba\de\1a\9a\0a\3f\35\9d\26\e0\d3\8c\af\4d\72\b9\b3\06\ff\5a\0b\12\00\18\8e\80\10\12\2a\0a\22\12\20\73\0d\db\a8\3e\31\47\bb\e1\07\80\b9\7f\f0\71\8c\74\c3\60\37\b9\7b\3b\79\b4\5c\45\11\80\65\45\81\12\00\18\8e\80\10\12\2a\0a\22\12\20\48\ea\9d\5d\42\3f\67\8d\83\d5\59\d2\34\9b\e8\32\55\27\29\0b\07\0c\90\fc\1a\cd\96\8f\0b\f7\0a\06\12\00\18\8e\80\10\0a\09\73\6f\6d\65\20\64\61\74\61";
        expectedCID = cidFromTextOrTrap("bafybeie7xh3zqqmeedkotykfsnj2pi4sacvvsjq6zddvcff4pq7dvyenhu");
      },
    ];

    let failures = List.empty<Text>();
    label f for (testCase in testCases.vals()) {
      let parsedNode = switch (DagPb.fromBytes(testCase.expectedBytes.vals())) {
        case (#ok(node)) node;
        case (#err(error)) Runtime.trap("Failed to deserialize node: " # error);
      };
      if (parsedNode != testCase.node) {
        let message = "fromBytes failed:\n\nExpected: " # debug_show (testCase.node) # "\n\nActual:   " # debug_show (parsedNode) # "\n\nBytes:   " # debug_show (testCase.expectedBytes);
        List.add(failures, message);
        continue f;
      };
      let actualBytes = switch (DagPb.toBytes(testCase.node)) {
        case (#ok(bytes)) Blob.fromArray(bytes);
        case (#err(error)) Runtime.trap("Failed to serialize node: " # error);
      };
      if (actualBytes != testCase.expectedBytes) {
        let message = "toBytes failed:\n\nExpected: " # debug_show (testCase.expectedBytes) # "\n\nActual:   " # debug_show (actualBytes) # "\n\nNode:     " # debug_show (testCase.node);
        List.add(failures, message);
        continue f;
      };
      let hash = Sha256.fromArray(#sha256, Blob.toArray(actualBytes));
      let actualCID = #v1({
        codec = #dagPb;
        hashAlgorithm = #sha2256;
        hash = hash;
      });
      if (actualCID != testCase.expectedCID) {
        let message = "CID mismatch:\n\nExpected: " # debug_show (testCase.expectedCID) # "\n\nActual:   " # debug_show (actualCID) # "\n\nNode:     " # debug_show (testCase.node);
        List.add(failures, message);
        continue f;
      };
    };
    if (List.size(failures) > 0) {
      let errorMessage = Text.join("\n---\n", List.values(failures));
      Runtime.trap(errorMessage);
    };
  },
);
