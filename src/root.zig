const std = @import("std");

pub const Passer = ?WalkReturn;
pub const TexprPass = ?*const fn () *const Texpr;
// TODO: change from a function-based approach to a hashmap one
// OR: change from a pass to a link after the first pass
pub const WalkReturn = struct {
    pass: TexprPass,
    this: ?*const Texpr = null,
    comp: u8 = 0,
    str: []const u8,
    index: u64,
    cache: ?[][]const u8,
    cache_len: u64,
    allocator: std.mem.Allocator,
    pub fn next(self: @This()) Passer {

        // std.debug.print("{s}\n", .{self.str[self.index..]});
        return self.pass.?(@constCast(&self));

        // if (self.this == null) return nxt;
        // if (nxt == null) return null;

        // var unsafeCast = @constCast(self.this.?);
        // unsafeCast.pass = null;
        // unsafeCast.next[self.comp] = nxt.?.this;

        // return nxt.?.next();
    }
    pub fn create(sr: []const u8, idx: u64, cche: ?[][]const u8, cl: u64, alc: std.mem.Allocator) WalkReturn {
        return @This(){ .pass = null, .str = sr, .index = idx, .cache = cche, .cache_len = cl, .allocator = alc };
    }

};

// add ignore / restore position
pub const TexprMethod = enum { none, include, exclude, onlyBefore, includeAll, ignore };
pub const Texpr = struct {
        next: [255]?*const Self = std.mem.zeroes([255]?*const Self),
        pass: TexprPass = null,
        method: TexprMethod = TexprMethod.none,
        final: ?[]const u8 = null,

        const Self = @This();

        fn option_base(current: Self, characters: []const u8, collectionMethod: TexprMethod, pass: TexprPass, next_texpr: ?*const Self) Self {
            return Self{ .next = insert_next_comptime(current, characters.ptr, characters, pass, next_texpr, collectionMethod), .pass = null, .method = TexprMethod.none, .final = null};
        }

        fn option_base_range(current: Self, from: u8, to: u8, collectionMethod: TexprMethod, pass: TexprPass, next_texpr: ?*const Self )Self {
            std.debug.assert(from <= 255 and to+1 <= 255);
            var next_list: [255]?*const Texpr = undefined;
            @memcpy(&next_list, &current.next);
            @setEvalBranchQuota(50000);
            for (from..to+1) |index| {
                if (next_list[index] == null) {
                    const replacement = &Self{ .next = std.mem.zeroes([255]?*const Self), .method = TexprMethod.none, .pass = null, .final = null  };
                    next_list[index] = &Self{ .next = (next_texpr orelse replacement).next, .method = collectionMethod, .pass = pass, .final = null };
                }
            }

            // return comptime Self{ .next = next_list, .pass = current.pass, .final = current.final, .method = current.method };
            return Self { .next = next_list, .pass = null, .method = TexprMethod.none, .final = null};
        }

        // pub fn tagged(comptime next: []const u8)  *const Texpr {
        //     return comptime get(next);
        // }

        // pub fn tag(current: *const Texpr, name: []const u8) *const Texpr {
        //     put(name, current);
        //     return current;
        // }
        pub fn include_match(current: Self, characters: []const u8, next_texpr: ?*const Self) Self {
            return option_base(current, characters, TexprMethod.include, null, next_texpr);
        }
        pub fn include_match_pass(current: Self, characters: []const u8, pass: TexprPass) Self {
            return option_base(current, characters, TexprMethod.include, pass, null);
        }
        pub fn skip_match(current: Self, characters: []const u8, next_texpr: ?*const Self) Self {
            return option_base(current, characters, TexprMethod.none, null, next_texpr);
        }
        pub fn skip_match_pass(current: Self, characters: []const u8, pass: TexprPass) Self {
            return option_base(current, characters, TexprMethod.none, pass, null);
        }
        pub fn exclude_match(current: Self, characters: []const u8, next_texpr: ?*const Self) Self {
            return option_base(current, characters, TexprMethod.exclude, null, next_texpr);
        }
        pub fn exclude_match_pass(current: Self, characters: []const u8, pass: TexprPass) Self {
            return option_base(current, characters, TexprMethod.exclude, pass, null);
        }
        pub fn collect_match(current: Self, characters: []const u8, next_texpr: ?*const Self) Self {
            return option_base(current, characters, TexprMethod.includeAll, null, next_texpr);
        }
        pub fn collect_match_pass(current: Self, characters: []const u8, pass: TexprPass) Self {
            return option_base(current, characters, TexprMethod.includeAll, pass, null);
        }
        pub fn before_match(current: Self, characters: []const u8, next_texpr: ?*const Self) Self {
            return option_base(current, characters, TexprMethod.onlyBefore, null, next_texpr);
        }
        pub fn before_match_pass(current: Self, characters: []const u8, pass: TexprPass) Self {
            return option_base(current, characters, TexprMethod.onlyBefore, pass, null);
        }
        pub fn ignore_match(current: Self, characters: []const u8) Self {
            return option_base(current, characters, TexprMethod.ignore, null, null);
        }
        pub fn ignore_match_pass(current: Self, characters: []const u8, pass: TexprPass) Self {
            return option_base(current, characters, TexprMethod.ignore, pass, null);
        }
        pub fn ignore_all(current: Self) Self {
            return option_base_range(current, 0, 254, TexprMethod.ignore, null, null);
        }
        pub fn ignore_pass_all(current: Self, pass: TexprPass) Self {
            return option_base_range(current, 0, 254, TexprMethod.ignore, pass, null);
        }
        pub fn include_range(current: Self, range: [2]u8, next_texpr: ?*const Self) Self {
            return option_base_range(current, range[0], range[1], TexprMethod.include, null, next_texpr);
        }
        pub fn include_range_pass(current: Self, range: [2]u8, pass: TexprPass, next_texpr: ?*const Self) Self {
            return option_base_range(current, range[0], range[1], TexprMethod.include, pass, next_texpr);
        }
        pub fn exclude_range(current: Self, range: [2]u8, next_texpr: ?*const Self) Self {
            return option_base_range(current, range[0], range[1], TexprMethod.exclude, null, next_texpr);
        }
        pub fn exclude_range_pass(current: Self, range: [2]u8, pass: TexprPass) Self {
            return option_base_range(current, range[0], range[1], TexprMethod.exclude, pass, null);
        }
        pub fn before_range(current: Self, range: [2]u8, next_texpr: ?*const Self) Self {
            return option_base_range(current, range[0], range[1], TexprMethod.onlyBefore, null, next_texpr);
        }
        pub fn before_range_pass(current: Self, range: [2]u8, pass: TexprPass) Self {
            return option_base_range(current, range[0], range[1], TexprMethod.onlyBefore, pass, null);
        }
        pub fn collect_range(current: Self, range: [2]u8, next_texpr: ?*const Self) Self {
            return option_base_range(current, range[0], range[1], TexprMethod.includeAll, null, next_texpr);
        }
        pub fn collect_range_pass(current: Self, range: [2]u8, pass: TexprPass) Self {
            return option_base_range(current, range[0], range[1], TexprMethod.includeAll, pass, null);
        }
        pub fn ignore_range(current: Self, range: [2]u8) Self {
            return  option_base_range(current, range[0], range[1], TexprMethod.ignore, null, null);
        }
        pub fn ignore_range_pass(current: Self, range: [2]u8, pass: TexprPass) Self {
            return option_base_range(current, range[0], range[1], TexprMethod.ignore, pass, null);
        }
        pub fn skip_range(current: Self, range: [2]u8, next_texpr: ?*const Self) Self {
            return option_base_range(current, range[0], range[1], TexprMethod.none, null, next_texpr);
        }
        pub fn skip_range_pass(current: Self, range: [2]u8, pass: TexprPass) Self {
            return option_base_range(current, range[0], range[1], TexprMethod.none, pass, null);
        }

        // TODO: when lang supports it, circular references
        pub fn walk(texpr: *const Self, str: []const u8, anyallocator: std.mem.Allocator) !void {
            var current: *const Self = texpr;
            var last_texpr: *const Self = texpr;

            var last: u64 = 0;
            var index: u64 = 0;

            var tokens: [][]const u8 = try anyallocator.alloc([]const u8, 4);
            var tokens_len: u64 = 0;


            while (index<str.len) {
                const char = str[index];
                index+=1;
                last_texpr = current;

                // TODO/IMPORTANT: make errors at comptime for unset values
                current = current.next[char].?;

                // std.debug.print("char: {c}, index: {any}, current: {any}\n", .{char, index, current.?.next['\'']});

                // std.debug.print("{c} | {any} | {any} \n", .{ char, index, last });
                switch (current.method) {
                        TexprMethod.include => {
                            std.debug.assert(current.final != null);
                            if (tokens_len + 2 > tokens.len) tokens = try anyallocator.realloc(tokens, tokens.len*2);
                            tokens[tokens_len] = current.final.?;
                            last = index;
                            tokens_len += 1;
                        },
                        TexprMethod.exclude => {
                            last = index;
                        },
                        TexprMethod.ignore => {
                            if (current.pass != null) {
                                current = current.pass.?();
                                // return pass function so hopefully the previous function can perform TCO
                                //return WalkReturn{.comp = char, .pass = current.pass.?, .str = data.str, .index = index, .cache = tokens, .cache_len = tokens_len, .allocator = data.allocator};
                            } else {
                                current = last_texpr;
                            }
                        },
                        TexprMethod.includeAll => {
                            if (tokens_len + 3 > tokens.len) tokens = try anyallocator.realloc(tokens, tokens.len*2);
                            // CHECK: unsafe unwrap here
                            const slice = str[last .. index - current.final.?.len];
                            tokens[tokens_len] = slice;
                            tokens[tokens_len+1] = current.final.?;
                            last = index + 1;
                            tokens_len += 2;
                        },
                        TexprMethod.onlyBefore => {
                            if (tokens_len + 2 > tokens.len) tokens = try anyallocator.realloc(tokens, tokens.len*2);
                            // CHECK: unsafe unwrap here
                            const slice = str[last .. index - current.final.?.len];
                            tokens[tokens_len] = slice;
                            last = index + 1;
                            tokens_len += 1;
                        },
                        TexprMethod.none => {
                            continue;
                        },
                    }

                if (current.pass != null) {
                    current = current.pass.?();
                    // return WalkReturn{.comp = char, .pass = current.pass.?, .str = data.str, .index = index, .cache = tokens, .cache_len = tokens_len, .allocator = data.allocator};
                }


            }
            // for (tokens) |t| {
            //     std.debug.print("{s}\n", .{t});
            // }
            // only free at end of pstr
            anyallocator.free(tokens);
        }

        pub fn insert_next_comptime(current: Self, characters: [*]const u8, full: []const u8, pass: TexprPass, next_texpr: ?*const Self, collectionMethod: TexprMethod) [255]?*const Self {
            const character = characters[0];
            if (character == 0) {
                if (next_texpr == null) {
                    return std.mem.zeroes([255]?*const Self);
                } else {
                    return next_texpr.?.next;
                }
            }
            if (current.next[character] == null) {
                var lcopy = current.next;
                if (characters[1] == 0) {

                    lcopy[character] = &Self{ .next = (next_texpr orelse Self{}).next, .pass = pass, .method = collectionMethod, .final = full  };
                } else {
                    lcopy[character] = &Self{ .next = insert_next_comptime(Self{ .next = std.mem.zeroes([255]?*const Self), .pass = null, .method = TexprMethod.none, .final = null,  }, characters + 1, full, pass, next_texpr, collectionMethod), .pass = null, .method = TexprMethod.none, .final = null };
                }
                return lcopy;
            } else {
                if (characters[1] == 0) {
                    return insert_next_comptime(Self{ .next = current.next, .pass = pass, .method = collectionMethod, .final = full  }, characters + 1, full, pass, next_texpr, collectionMethod);
                } else {
                    return insert_next_comptime(Self{ .next = current.next, .pass = null, .method = TexprMethod.none, .final = null  }, characters + 1, full, pass, next_texpr, collectionMethod);
                }
            }
        }

        // fn insert_next(self: *const Self, full: []const u8, pass: TexprPass, next_texpr: ?*const Self, method: TexprMethod) Self {
        //     var current: Self = self;
        //     for (full, 0..) |character, index| {

        //         var modify_list = @constCast(&current.next);
        //         if (index+1 >= full.len) {
        //             if (next_texpr != null) {
        //                 next_texpr.?.pass = pass;
        //                 next_texpr.?.final = full;
        //                 next_texpr.?.method = method;
        //                 modify_list[character] = next_texpr.?;
        //             } else {
        //                 modify_list[character] =  &Self { .next = std.mem.zeroes([255]?*const Self),  .pass = pass, .method = method, .final = full};
        //             }
        //         }

        //         if (current.next[character] == null) {

        //             modify_list[character] = &Self { .next = std.mem.zeroes([255]?*const Self),  .pass = null, .method = TexprMethod.none, .final = null};
        //             current = modify_list[character].?;
        //         } else {
        //             current = modify_list[character].?;
        //         }


        //     }
        //     return self;
        // }

        // pub fn set(self: *const Self, value: Self) void {
        //     for (0..255) |index| {
        //         self.*.next[index] = value.next[index];
        //     }
        // }


        // pub fn direct(set: []?*const Self) Self {
        //     return pushNew()
        // }

        // pub fn pushNew(set: []?*const Self, new: *const Self)  {
        //     var index = 0;
        //     for (set, 0..) |item, index| {
        //         if (item == null) {

        //             break;
        //         }
        //     }
        //     return &set[index];
        // }

        pub fn ref(toRef: *const Self) Self {
            toRef.* = Texpr.init();
            return toRef;
        }

        pub fn from_cache(cache: []Texpr, size: *u64) *Texpr {
            cache[size.*] = Texpr.init();

            size.*+=1;
            return &cache[size.*-1];
        }



};

pub fn init() Texpr {
    return Texpr{ .next = std.mem.zeroes([255]?*const Texpr), .pass = null, .method = TexprMethod.none, .final = null  };
}
