(module
    (global $length (import "js" "length") i32)
    (memory $colors (import "js" "colors") 1)

    (func $color (export "getColor")
        (param $index i32)
        (result i32)
        get_local $index
        i32.const -1
        i32.eq
        ;; return "background color" from end of memory when index is -1
        if (result i32)
            get_global $length
        ;; otherwise, return rgba color at index
        else
            get_local $index
            get_global $length
            i32.rem_u
        end
        i32.const 4
        i32.mul
        i32.load
    )
)