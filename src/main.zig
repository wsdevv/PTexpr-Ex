const std = @import("std");
const texpr = @import("root.zig");
usingnamespace texpr;
// const StringView = struct { ptr: [*]u8, len: u64 };


pub fn err() *texpr.Texpr {
    std.debug.panic("[ERROR]: Unknown token '' at ", .{});
}


// fn end_table(data: *texpr.WalkReturn) texpr.Passer {
//     return value(data);
// }

// fn start_table(data: *texpr.WalkReturn) texpr.Passer {
//     return value(data);
// }

fn value() *const texpr.Texpr {
    return &comptime texpr.init()
        .ignore_match(" ")
        .skip_range(.{'0', '9'},
            &texpr.init()
                .ignore_range(.{'0', '9'})
                .ignore_match(" ") // TODO: make it so we can't place spaces in between numbers
                .before_match_pass(",", key)
                .before_match("}", null)
                .ignore_pass_all(err)
        )
        // TODO
        .exclude_match("'",
            &texpr.init()
            .before_match("'",
                &texpr.init()
                    .exclude_match_pass(",", key)
                    .exclude_match("}", null)
                    .ignore_pass_all(err)
            )
            .ignore_all()
        )
        // TODO
        .exclude_match_pass("{", key)
        .ignore_pass_all(err)
        ;

    //return set_value.walk(data) catch null;
}

// TODO: include escape sequences
fn key() *const texpr.Texpr {

    //std.debug.print("hello");
    const colon_equals = &comptime texpr.init()
    	.ignore_match("\n")
        .ignore_match(" ")
        .exclude_match_pass(":", value)
        //.ignore_pass_all(err)
        ;

    return &comptime texpr.init()
        .exclude_match("'",
            &texpr.init()
            .before_match("'", colon_equals)
            .ignore_all()
        )
        .exclude_match("\"",
            &texpr.init()
            .before_match("\"", colon_equals)
            .ignore_all()
        )
        .ignore_match("\n")
        .ignore_match(" ")
        .ignore_pass_all(err)
        ;

    //return key_match.walk(data) catch null;
}

fn parse() *const texpr.Texpr {
    return &comptime texpr.init()
            .include_match_pass("{",
                 key
            )
            .ignore_match("\n")
            .ignore_pass_all(err)
            ;
}


pub fn main() !void {




    // _ = Texpr{ .next = comptime insert_next(&Texpr{ .next = std.mem.zeroes([255]?*const Texpr), .pass = null }, "hyu\n"), .pass = null };
    // const nextpr = comptime insert_next(&Texp)
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpallacator = gpa.allocator();
    defer {
         _ = gpa.deinit();
    }


   // const buf = @embedFile("test.json");
    //var data = texpr.WalkReturn.create(@embedFile("test.json"), 0, null, 0, gpallacator);
    try parse().walk(@embedFile("test.json"), gpallacator);

    // while (walker!=null) {
    //     walker = walker.?.next();
    // }

    return;
}
