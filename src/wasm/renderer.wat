(module
    (global $width  (import "js" "width" ) i32) ;; image width
    (global $height (import "js" "height") i32) ;; image height
    (func  $color (import "js" "getColor") (param i32) (result i32))
    (memory $data (export "imageData") 1)
    (start $adjust_memory)
    (func $adjust_memory
        ;; adjust memory size
        ;; please don't try to render 4.3 Billion pixels at once
        get_global $width
        get_global $height
        i32.mul
        i32.const 4
        i32.mul
        i32.const 65536
        i32.div_u
        grow_memory
        drop
    )
    (func $render (export "render")
        (param $left f64)   ;; real part of left border
        (param $top f64)    ;; imaginary part of top border
        (param $scale f64)  ;; units / pixel
        (param $depth i32)  ;; max iterations

        (local $c_r f64) ;; complex number - real
        (local $c_i f64) ;;   and imaginary parts
        (local $x i32) ;; current pixel
        (local $y i32) ;;   coordinates

        i32.const 0
        set_local $y
        get_local $top
        set_local $c_i
        loop $rows
            i32.const 0
            set_local $x
            get_local $left
            set_local $c_r
            loop $cols
                ;; byte offset
                get_local $y
                get_global $width
                i32.mul
                get_local $x
                i32.add
                i32.const 4
                i32.mul

                ;; rgba pixel color
                get_local $c_r
                get_local $c_i
                get_local $depth
                call $steps
                call $color

                ;; write to memory
                i32.store

                ;; x++
                get_local $x
                i32.const 1
                i32.add
                set_local $x

                ;; c_r += scale
                get_local $c_r
                get_local $scale
                f64.add
                set_local $c_r

                ;; loop if x < width
                get_local $x
                get_global $width
                i32.lt_u
                br_if $cols
            end

            ;; y++
            get_local $y
            i32.const 1
            i32.add
            set_local $y

            ;; c_i -= scale
            get_local $c_i
            get_local $scale
            f64.sub
            set_local $c_i

            ;; loop if y < height
            get_local $y
            get_global $height
            i32.lt_u
            br_if $rows
        end
    )

    (func $steps
        (param $c_r f64) ;; c_real
        (param $c_i f64) ;; c_imaginary
        (param $d i32)   ;; max depth
        (result i32)
        (local $z_r f64) ;; z_real
        (local $z_i f64) ;; z_imaginary
        (local $i i32)   ;; iteration counter

        get_local $c_r
        set_local $z_r
        get_local $c_i
        set_local $z_i
        i32.const 0
        set_local $i

        loop $zoop
            ;; if s >= d
            get_local $i
            get_local $d
            i32.ge_u
            if
                ;; return -1
                i32.const -1
                set_local $i
            else
                ;; if abs(z) <= 2
                get_local $z_r
                get_local $z_r
                f64.mul
                get_local $z_i
                get_local $z_i
                f64.mul
                f64.add
                f64.const 4
                f64.le
                if
                    ;; z' = z*z + c
                    ;; z'_r = z_r*z_r - z_i*z_i + c_r
                    get_local $z_r
                    get_local $z_r
                    f64.mul
                    get_local $z_i
                    get_local $z_i
                    f64.mul
                    f64.sub
                    get_local $c_r
                    f64.add

                    ;; z'_i = z_r*z_i + z_i*z_r + c_i
                    get_local $z_r
                    get_local $z_i
                    f64.mul
                    get_local $z_i
                    get_local $z_r
                    f64.mul
                    f64.add
                    get_local $c_i
                    f64.add

                    set_local $z_i
                    set_local $z_r

                    ;; s++
                    get_local $i
                    i32.const 1
                    i32.add
                    set_local $i
                    br $zoop
                end
            end
        end

        get_local $i
    )
)