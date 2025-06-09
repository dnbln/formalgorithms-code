pragma Ada_2012;

pragma Style_Checks (Off);
pragma Warnings (Off, "-gnatwu");

with Interfaces.C; use Interfaces.C;
with sys_utypes_uoff_t_h;
with sys_utypes_upid_t_h;
with sys_utypes_utimespec_h;
with System;
with sys_utypes_usize_t_h;
with Interfaces.C.Strings;
with sys_utypes_umode_t_h;
with sys_utypes_ufilesec_t_h;

package sys_fcntl_h is

   O_RDONLY : constant := 16#0000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:96
   O_WRONLY : constant := 16#0001#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:97
   O_RDWR : constant := 16#0002#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:98
   O_ACCMODE : constant := 16#0003#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:99

   FREAD : constant := 16#00000001#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:110
   FWRITE : constant := 16#00000002#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:111

   O_NONBLOCK : constant := 16#00000004#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:113
   O_APPEND : constant := 16#00000008#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:114

   O_SHLOCK : constant := 16#00000010#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:119
   O_EXLOCK : constant := 16#00000020#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:120
   O_ASYNC : constant := 16#00000040#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:121
   --  unsupported macro: O_FSYNC O_SYNC

   O_NOFOLLOW : constant := 16#00000100#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:123

   O_CREAT : constant := 16#00000200#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:125
   O_TRUNC : constant := 16#00000400#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:126
   O_EXCL : constant := 16#00000800#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:127

   O_EVTONLY : constant := 16#00008000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:130

   O_NOCTTY : constant := 16#00020000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:134

   O_DIRECTORY : constant := 16#00100000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:138
   O_SYMLINK : constant := 16#00200000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:139

   O_CLOEXEC : constant := 16#01000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:147

   O_NOFOLLOW_ANY : constant := 16#20000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:152

   AT_FDCWD : constant := -2;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:160

   AT_EACCESS : constant := 16#0010#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:165
   AT_SYMLINK_NOFOLLOW : constant := 16#0020#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:166
   AT_SYMLINK_FOLLOW : constant := 16#0040#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:167
   AT_REMOVEDIR : constant := 16#0080#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:168

   AT_REALDEV : constant := 16#0200#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:170
   AT_FDONLY : constant := 16#0400#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:171

   O_DP_GETRAWENCRYPTED : constant := 16#0001#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:177
   O_DP_GETRAWUNENCRYPTED : constant := 16#0002#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:178
   --  unsupported macro: FAPPEND O_APPEND
   --  unsupported macro: FASYNC O_ASYNC
   --  unsupported macro: FFSYNC O_FSYNC
   --  unsupported macro: FFDSYNC O_DSYNC
   --  unsupported macro: FNONBLOCK O_NONBLOCK
   --  unsupported macro: FNDELAY O_NONBLOCK
   --  unsupported macro: O_NDELAY O_NONBLOCK

   CPF_OVERWRITE : constant := 16#0001#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:203
   CPF_IGNORE_MODE : constant := 16#0002#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:204
   --  unsupported macro: CPF_MASK (CPF_OVERWRITE|CPF_IGNORE_MODE)

   F_DUPFD : constant := 0;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:213
   F_GETFD : constant := 1;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:214
   F_SETFD : constant := 2;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:215
   F_GETFL : constant := 3;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:216
   F_SETFL : constant := 4;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:217
   F_GETOWN : constant := 5;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:218
   F_SETOWN : constant := 6;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:219
   F_GETLK : constant := 7;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:220
   F_SETLK : constant := 8;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:221
   F_SETLKW : constant := 9;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:222

   F_SETLKWTIMEOUT : constant := 10;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:224

   F_FLUSH_DATA : constant := 40;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:227
   F_CHKCLEAN : constant := 41;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:228
   F_PREALLOCATE : constant := 42;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:229
   F_SETSIZE : constant := 43;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:230
   F_RDADVISE : constant := 44;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:231
   F_RDAHEAD : constant := 45;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:232

   F_NOCACHE : constant := 48;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:236
   F_LOG2PHYS : constant := 49;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:237
   F_GETPATH : constant := 50;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:238
   F_FULLFSYNC : constant := 51;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:239
   F_PATHPKG_CHECK : constant := 52;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:240
   F_FREEZE_FS : constant := 53;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:241
   F_THAW_FS : constant := 54;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:242
   F_GLOBAL_NOCACHE : constant := 55;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:243

   F_ADDSIGS : constant := 59;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:246

   F_ADDFILESIGS : constant := 61;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:249

   F_NODIRECT : constant := 62;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:251

   F_GETPROTECTIONCLASS : constant := 63;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:254
   F_SETPROTECTIONCLASS : constant := 64;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:255

   F_LOG2PHYS_EXT : constant := 65;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:257

   F_GETLKPID : constant := 66;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:259

   F_SETBACKINGSTORE : constant := 70;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:264
   F_GETPATH_MTMINFO : constant := 71;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:265

   F_GETCODEDIR : constant := 72;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:267

   F_SETNOSIGPIPE : constant := 73;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:269
   F_GETNOSIGPIPE : constant := 74;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:270

   F_TRANSCODEKEY : constant := 75;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:272

   F_SINGLE_WRITER : constant := 76;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:274

   F_GETPROTECTIONLEVEL : constant := 77;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:277

   F_FINDSIGS : constant := 78;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:279

   F_ADDFILESIGS_FOR_DYLD_SIM : constant := 83;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:282

   F_BARRIERFSYNC : constant := 85;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:285

   F_ADDFILESIGS_RETURN : constant := 97;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:288
   F_CHECK_LV : constant := 98;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:289

   F_PUNCHHOLE : constant := 99;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:291

   F_TRIM_ACTIVE_FILE : constant := 100;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:293

   F_SPECULATIVE_READ : constant := 101;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:295

   F_GETPATH_NOFIRMLINK : constant := 102;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:297

   F_ADDFILESIGS_INFO : constant := 103;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:299
   F_ADDFILESUPPL : constant := 104;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:300
   F_GETSIGSINFO : constant := 105;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:301

   FCNTL_FS_SPECIFIC_BASE : constant := 16#00010000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:304

   F_DUPFD_CLOEXEC : constant := 67;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:309

   FD_CLOEXEC : constant := 1;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:313

   F_RDLCK : constant := 1;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:316
   F_UNLCK : constant := 2;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:317
   F_WRLCK : constant := 3;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:318

   F_ALLOCATECONTIG : constant := 16#00000002#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:336
   F_ALLOCATEALL : constant := 16#00000004#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:337

   F_PEOFPOSMODE : constant := 3;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:341

   F_VOLPOSMODE : constant := 4;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:343

   USER_FSIGNATURES_CDHASH_LEN : constant := 20;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:390

   GETSIGSINFO_PLATFORM_BINARY : constant := 1;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:433

   LOCK_SH : constant := 16#01#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:444
   LOCK_EX : constant := 16#02#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:445
   LOCK_NB : constant := 16#04#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:446
   LOCK_UN : constant := 16#08#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:447

   O_POPUP : constant := 16#80000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:525
   O_ALERT : constant := 16#20000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:526
   --  unsupported macro: FILESEC_GUID FILESEC_UUID

  -- * Copyright (c) 2000-2013 Apple Inc. All rights reserved.
  -- *
  -- * @APPLE_OSREFERENCE_LICENSE_HEADER_START@
  -- *
  -- * This file contains Original Code and/or Modifications of Original Code
  -- * as defined in and that are subject to the Apple Public Source License
  -- * Version 2.0 (the 'License'). You may not use this file except in
  -- * compliance with the License. The rights granted to you under the License
  -- * may not be used to create, or enable the creation or redistribution of,
  -- * unlawful or unlicensed copies of an Apple operating system, or to
  -- * circumvent, violate, or enable the circumvention or violation of, any
  -- * terms of an Apple operating system software license agreement.
  -- *
  -- * Please obtain a copy of the License at
  -- * http://www.opensource.apple.com/apsl/ and read it before using this file.
  -- *
  -- * The Original Code and all software distributed under the License are
  -- * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
  -- * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
  -- * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
  -- * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
  -- * Please see the License for the specific language governing rights and
  -- * limitations under the License.
  -- *
  -- * @APPLE_OSREFERENCE_LICENSE_HEADER_END@
  --  

  -- Copyright (c) 1995 NeXT Computer, Inc. All Rights Reserved  
  ---
  -- * Copyright (c) 1983, 1990, 1993
  -- *	The Regents of the University of California.  All rights reserved.
  -- * (c) UNIX System Laboratories, Inc.
  -- * All or some portions of this file are derived from material licensed
  -- * to the University of California by American Telephone and Telegraph
  -- * Co. or Unix System Laboratories, Inc. and are reproduced herein with
  -- * the permission of UNIX System Laboratories, Inc.
  -- *
  -- * Redistribution and use in source and binary forms, with or without
  -- * modification, are permitted provided that the following conditions
  -- * are met:
  -- * 1. Redistributions of source code must retain the above copyright
  -- *    notice, this list of conditions and the following disclaimer.
  -- * 2. Redistributions in binary form must reproduce the above copyright
  -- *    notice, this list of conditions and the following disclaimer in the
  -- *    documentation and/or other materials provided with the distribution.
  -- * 3. All advertising materials mentioning features or use of this software
  -- *    must display the following acknowledgement:
  -- *	This product includes software developed by the University of
  -- *	California, Berkeley and its contributors.
  -- * 4. Neither the name of the University nor the names of its contributors
  -- *    may be used to endorse or promote products derived from this software
  -- *    without specific prior written permission.
  -- *
  -- * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
  -- * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  -- * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  -- * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
  -- * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  -- * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
  -- * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
  -- * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
  -- * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
  -- * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
  -- * SUCH DAMAGE.
  -- *
  -- *	@(#)fcntl.h	8.3 (Berkeley) 1/21/94
  --  

  -- * This file includes the definitions for open and fcntl
  -- * described by POSIX for <fcntl.h>; it also includes
  -- * related kernel definitions.
  --  

  -- We should not be exporting size_t here.  Temporary for gcc bootstrapping.  
  -- * File status flags: these are used by open(2), fcntl(2).
  -- * They are also used (indirectly) in the kernel file structure f_flags,
  -- * which is a superset of the open/fcntl flags.  Open flags and f_flags
  -- * are inter-convertible using OFLAGS(fflags) and FFLAGS(oflags).
  -- * Open/fcntl flags begin with O_; kernel-internal flags begin with F.
  --  

  -- open-only flags  
  -- * Kernel encoding of open mode; separate read and write bits that are
  -- * independently testable: 1 greater than the above.
  -- *
  -- * XXX
  -- * FREAD and FWRITE are excluded from the #ifdef KERNEL so that TIOCFLUSH,
  -- * which was documented to use FREAD/FWRITE, continues to work.
  --  

  --      O_DSYNC         0x00400000      /* synch I/O data integrity  
  -- * Descriptor value for the current working directory
  --  

  -- * Flags for the at functions
  --  

  -- Data Protection Flags  
  -- * The O_* flags used to have only F* names, which were used in the kernel
  -- * and by fcntl.  We retain the F* names for the kernel f_flags field
  -- * and for backward compatibility for fcntl.
  --  

  -- * Flags used for copyfile(2)
  --  

  -- * Constants used for fcntl(2)
  --  

  -- command values  
  -- * 46,47 used to be F_READBOOTSTRAP and F_WRITEBOOTSTRAP
  --  

  -- should not be used (i.e. its ok to temporaily create cached pages)  
  -- See F_DUPFD_CLOEXEC below for 67  
  -- may be broken into smaller chunks with throttling in between  
  -- FS-specific fcntl()'s numbers begin at 0x00010000 and go up
  -- file descriptor flags (F_GETFD, F_SETFD)  
  -- record locking flags (F_GETLK, F_SETLK, F_SETLKW)  
  -- * [XSI] The values used for l_whence shall be defined as described
  -- * in <unistd.h>
  --  

  -- * [XSI] The symbolic names for file modes for use as values of mode_t
  -- * shall be defined as described in <sys/stat.h>
  --  

  -- allocate flags (F_PREALLOCATE)  
  -- Position Modes (fst_posmode) for F_PREALLOCATE  
  -- we can keep them in sync should we desire  
  -- * Advisory file segment locking data type -
  -- * information passed to system by user
  --  

  -- starting offset  
   type flock is record
      l_start : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:351
      l_len : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:352
      l_pid : aliased sys_utypes_upid_t_h.pid_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:353
      l_type : aliased short;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:354
      l_whence : aliased short;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:355
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:350

  -- len = 0 means until end of file  
  -- lock owner  
  -- lock type: read/write, etc.  
  -- type of l_start  
  -- * Advisory file segment locking with time out -
  -- * Information passed to system by user for F_SETLKWTIMEOUT
  --  

  -- flock passed for file locking  
   type flocktimeout is record
      fl : aliased flock;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:366
      timeout : aliased sys_utypes_utimespec_h.timespec;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:367
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:365

  -- timespec struct for timeout  
  -- * advisory file read data type -
  -- * information passed by user to system
  --  

   type radvisory is record
      ra_offset : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:379
      ra_count : aliased int;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:380
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:378

  -- * detached code signatures data type -
  -- * information passed by user to system used by F_ADDSIGS and F_ADDFILESIGS.
  -- * F_ADDFILESIGS is a shortcut for files that contain their own signature and
  -- * doesn't require mapping of the file in order to load the signature.
  --  

   subtype anon_array1208 is Interfaces.C.char_array (0 .. 19);
   type fsignatures is record
      fs_file_start : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:392
      fs_blob_start : System.Address;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:393
      fs_blob_size : aliased sys_utypes_usize_t_h.size_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:394
      fs_fsignatures_size : aliased sys_utypes_usize_t_h.size_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:398
      fs_cdhash : aliased anon_array1208;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:399
      fs_hash_type : aliased int;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:400
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:391

  -- The following fields are only applicable to F_ADDFILESIGS_INFO (64bit only).  
  -- Prior to F_ADDFILESIGS_INFO, this struct ended after fs_blob_size.  
  -- input: size of this struct (for compatibility)
  -- output: cdhash
  -- output: hash algorithm type for cdhash
   subtype fsignatures_t is fsignatures;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:401

  -- offset of Mach-O image in FAT file   
   type fsupplement is record
      fs_file_start : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:404
      fs_blob_start : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:405
      fs_blob_size : aliased sys_utypes_usize_t_h.size_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:406
      fs_orig_fd : aliased int;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:407
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:403

  -- offset of signature in Mach-O image  
  -- signature blob size                  
  -- address of original image            
   subtype fsupplement_t is fsupplement;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:408

  -- * DYLD needs to check if the object is allowed to be combined
  -- * into the main binary. This is done between the code signature
  -- * is loaded and dyld is doing all the work to process the LOAD commands.
  -- *
  -- * While this could be done in F_ADDFILESIGS.* family the hook into
  -- * the MAC module doesn't say no when LV isn't enabled and then that
  -- * is cached on the vnode, and the MAC module never gets change once
  -- * a process that library validation enabled.
  --  

   type fchecklv is record
      lv_file_start : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:423
      lv_error_message_size : aliased sys_utypes_usize_t_h.size_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:424
      lv_error_message : System.Address;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:425
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:422

   subtype fchecklv_t is fchecklv;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:426

  -- At this time F_GETSIGSINFO can only indicate platformness.
  -- *  As additional requestable information is defined, new keys will be added and the
  -- *  fgetsigsinfo_t structure will be lengthened to add space for the additional information
  --  

  -- fgetsigsinfo_t used by F_GETSIGSINFO command  
  -- IN: Offset in the file to look for a signature, -1 for any signature  
   type fgetsigsinfo is record
      fg_file_start : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:437
      fg_info_request : aliased int;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:438
      fg_sig_is_platform : aliased int;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:439
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:436

  -- IN: Key indicating the info requested  
  -- OUT: 1 if the signature is a plat form binary, 0 if not  
   subtype fgetsigsinfo_t is fgetsigsinfo;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:440

  -- lock operations for flock(2)  
  -- fstore_t type used by F_PREALLOCATE command  
  -- IN: flags word  
   type fstore is record
      fst_flags : aliased unsigned;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:452
      fst_posmode : aliased int;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:453
      fst_offset : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:454
      fst_length : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:455
      fst_bytesalloc : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:456
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:451

  -- IN: indicates use of offset field  
  -- IN: start of the region  
  -- IN: size of the region  
  -- OUT: number of bytes allocated  
   subtype fstore_t is fstore;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:457

  -- fpunchhole_t used by F_PUNCHHOLE  
  -- unused  
   type fpunchhole is record
      fp_flags : aliased unsigned;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:461
      reserved : aliased unsigned;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:462
      fp_offset : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:463
      fp_length : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:464
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:460

  -- (to maintain 8-byte alignment)  
  -- IN: start of the region  
  -- IN: size of the region  
   subtype fpunchhole_t is fpunchhole;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:465

  -- factive_file_trim_t used by F_TRIM_ACTIVE_FILE  
  -- IN: start of the region  
   type ftrimactivefile is record
      fta_offset : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:469
      fta_length : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:470
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:468

  -- IN: size of the region  
   subtype ftrimactivefile_t is ftrimactivefile;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:471

  -- fspecread_t used by F_SPECULATIVE_READ  
  -- IN: flags word  
   type fspecread is record
      fsr_flags : aliased unsigned;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:475
      reserved : aliased unsigned;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:476
      fsr_offset : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:477
      fsr_length : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:478
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:474

  -- to maintain 8-byte alignment  
  -- IN: start of the region  
  -- IN: size of the region  
   subtype fspecread_t is fspecread;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:479

  -- fbootstraptransfer_t used by F_READBOOTSTRAP and F_WRITEBOOTSTRAP commands  
  -- IN: offset to start read/write  
   type fbootstraptransfer is record
      fbt_offset : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:484
      fbt_length : aliased sys_utypes_usize_t_h.size_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:485
      fbt_buffer : System.Address;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:486
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:483

  -- IN: number of bytes to transfer  
  -- IN: buffer to be read/written  
   subtype fbootstraptransfer_t is fbootstraptransfer;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:487

  -- * For F_LOG2PHYS this information is passed back to user
  -- * Currently only devoffset is returned - that is the VOP_BMAP
  -- * result - the disk device address corresponding to the
  -- * current file offset (likely set with an lseek).
  -- *
  -- * The flags could hold an indication of whether the # of
  -- * contiguous bytes reflects the true extent length on disk,
  -- * or is an advisory value that indicates there is at least that
  -- * many bytes contiguous.  For some filesystems it might be too
  -- * inefficient to provide anything beyond the advisory value.
  -- * Flags and contiguous bytes return values are not yet implemented.
  -- * For them the fcntl will nedd to switch from using BMAP to CMAP
  -- * and a per filesystem type flag will be needed to interpret the
  -- * contiguous bytes count result from CMAP.
  -- *
  -- * F_LOG2PHYS_EXT is a variant of F_LOG2PHYS that uses a passed in
  -- * file offset and length instead of the current file offset.
  -- * F_LOG2PHYS_EXT operates on the same structure as F_LOG2PHYS, but
  -- * treats it as an in/out.
  --  

  -- unused so far  
   type log2phys is record
      l2p_flags : aliased unsigned;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:514
      l2p_contigbytes : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:515
      l2p_devoffset : aliased sys_utypes_uoff_t_h.off_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:518
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:513

  -- F_LOG2PHYS:     unused so far  
  -- F_LOG2PHYS_EXT: IN:  number of bytes to be queried  
  --                 OUT: number of contiguous bytes at this position  
  -- F_LOG2PHYS:     OUT: bytes into device  
  -- F_LOG2PHYS_EXT: IN:  bytes into file  
  --                 OUT: bytes into device  
  -- XXX these are private to the implementation  
   subtype filesec_property_t is unsigned;
   filesec_property_t_FILESEC_OWNER : constant filesec_property_t := 1;
   filesec_property_t_FILESEC_GROUP : constant filesec_property_t := 2;
   filesec_property_t_FILESEC_UUID : constant filesec_property_t := 3;
   filesec_property_t_FILESEC_MODE : constant filesec_property_t := 4;
   filesec_property_t_FILESEC_ACL : constant filesec_property_t := 5;
   filesec_property_t_FILESEC_GRPUUID : constant filesec_property_t := 6;
   filesec_property_t_FILESEC_ACL_RAW : constant filesec_property_t := 100;
   filesec_property_t_FILESEC_ACL_ALLOCSIZE : constant filesec_property_t := 101;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:547

  -- XXX backwards compatibility  
   function open (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : int  -- , ...
      ) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:554
   with Import => True, 
        Convention => C, 
        External_Name => "open";

   function openat
     (arg1 : int;
      arg2 : Interfaces.C.Strings.chars_ptr;
      arg3 : int  -- , ...
      ) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:556
   with Import => True, 
        Convention => C, 
        External_Name => "_openat";

   function creat (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : sys_utypes_umode_t_h.mode_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:558
   with Import => True, 
        Convention => C, 
        External_Name => "_creat";

   function fcntl (arg1 : int; arg2 : int  -- , ...
      ) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:559
   with Import => True, 
        Convention => C, 
        External_Name => "fcntl";

   function openx_np
     (arg1 : Interfaces.C.Strings.chars_ptr;
      arg2 : int;
      arg3 : sys_utypes_ufilesec_t_h.filesec_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:562
   with Import => True, 
        Convention => C, 
        External_Name => "openx_np";

  -- * data-protected non-portable open(2) :
  -- *  int open_dprotected_np(user_addr_t path, int flags, int class, int dpflags, int mode)
  --  

   function open_dprotected_np
     (arg1 : Interfaces.C.Strings.chars_ptr;
      arg2 : int;
      arg3 : int;
      arg4 : int  -- , ...
      ) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:567
   with Import => True, 
        Convention => C, 
        External_Name => "open_dprotected_np";

   function flock_fn (arg1 : int; arg2 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:568
   with Import => True, 
        Convention => C, 
        External_Name => "flock";

   function filesec_init return sys_utypes_ufilesec_t_h.filesec_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:569
   with Import => True, 
        Convention => C, 
        External_Name => "filesec_init";

   function filesec_dup (arg1 : sys_utypes_ufilesec_t_h.filesec_t) return sys_utypes_ufilesec_t_h.filesec_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:570
   with Import => True, 
        Convention => C, 
        External_Name => "filesec_dup";

   procedure filesec_free (arg1 : sys_utypes_ufilesec_t_h.filesec_t)  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:571
   with Import => True, 
        Convention => C, 
        External_Name => "filesec_free";

   function filesec_get_property
     (arg1 : sys_utypes_ufilesec_t_h.filesec_t;
      arg2 : filesec_property_t;
      arg3 : System.Address) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:572
   with Import => True, 
        Convention => C, 
        External_Name => "filesec_get_property";

   function filesec_query_property
     (arg1 : sys_utypes_ufilesec_t_h.filesec_t;
      arg2 : filesec_property_t;
      arg3 : access int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:573
   with Import => True, 
        Convention => C, 
        External_Name => "filesec_query_property";

   function filesec_set_property
     (arg1 : sys_utypes_ufilesec_t_h.filesec_t;
      arg2 : filesec_property_t;
      arg3 : System.Address) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:574
   with Import => True, 
        Convention => C, 
        External_Name => "filesec_set_property";

   function filesec_unset_property (arg1 : sys_utypes_ufilesec_t_h.filesec_t; arg2 : filesec_property_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h:575
   with Import => True, 
        Convention => C, 
        External_Name => "filesec_unset_property";

end sys_fcntl_h;

pragma Style_Checks (On);
pragma Warnings (On, "-gnatwu");
