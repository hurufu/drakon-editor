package require struct::stack

namespace eval gen_ada {

    set block_stack [::struct::stack]

    proc name {i f s} {return "-- [info level 2] i:$i f:$f s:$s"}

    proc assign {lhs rhs} {
        return "[string trim [string trim $lhs] {_}] := [string trim $rhs]; -- assign"
    }
    proc bad_case {switch_var select_icon_number} {return "raise Bad_Case; -- bad_case"}
    proc block_close {output depth} {
        upvar 1 $output result
        variable block_stack
        lappend result "[gen::make_indent $depth]end [$block_stack pop]; -- block_close"
    }
    proc comment {line} {return "-- $line"}
    proc compare {var constant} {
        return "[string trim [string trim $constant] {_}] = [string trim [string trim $var] {_}]"
    }
    proc else_start {} {return "else -- else_start"}
    proc elseif_start {} {return "else if -- elseif_start"}
    proc for_check {item_id first second} {name $item_id $first $second}
    proc for_current {item_id first second} {name $item_id $first $second}
    proc for_declare {item_id first second} {name $item_id $first $second}
    proc for_incr {item_id first second} {name $item_id $first $second}
    proc for_init {item_id first second} {name $item_id $first $second}
    proc if_end {} {return " then -- if_end"}
    proc if_start {} {
        variable block_stack
        $block_stack push "if"
        return "if "
    }
    proc native_foreach {for_it for_var} {
        variable block_stack
        $block_stack push "loop"
        return "for $for_it $for_var loop -- native_foreach"
    }
    proc and {lhs rhs} {
        return "[string trim [string trim $lhs] {_}] and [string trim [string trim $rhs] {_}]"
    }
    proc continue {} {return "-- continue"}
    proc declare {type name value} {
        if {$value == {}} {
            return "declare\n[string trim $name {_}]: $type; -- declare\nbegin"
        } else {
            return "declare\n[string trim $name {_}]: $type; -- := $value; -- declare\nbegin"
        }
    }
    proc not {operand} {
        return "not [string trim [string trim $operand] {_}]"
    }
    proc or {lhs rhs} {
        return "[string trim [string trim $lhs] {_}] or [string trim [string trim $rhs] {_}]"
    }
    proc pass {} {return "null; -- pass"}
    proc return_none {} {return "return; -- return_none"}
    proc shelf {bottom up} {
        switch -glob $up {
            {*.} {
                set ret {}
                foreach line [split $bottom "\n"] {
                    lappend ret "[string trim $up]$line;"
                }
                return "[join $ret "\n"] -- shelf"
            }
            {raise} {
                return "raise $bottom;"
            }
            default {
                return "[string trim $up] := [string trim $bottom]; -- shelf"
            }
        }
    }
    proc while_start {} {
        variable block_stack
        $block_stack push "loop"
        return "loop -- while_start"
    }
    proc body {gdb diagram_id start_item node_list sorted incoming} {
        error {body callback isn't implemented}
    }
    proc body_end {} {
        return "end;"
    }
    proc break {} {return "exit -- break"}
    proc case_else {} {return "-- case_else"}
    proc case_end {next_text} {return "-- case_end $next_text"}
    proc case_value {txt} {return "-- case_value $txt"}
    proc change_state {next_state machine_name returns} {return "-- change_state $next_state $machine_name $returns"}
    proc fsm_merge {} {return 1}
    proc goto {txt} {return "goto $txt; -- goto"}
    proc select {header_text} {return "-- select $header_text"}
    proc select_end {} {return "-- select_end"}
    proc shutdown {} {return "-- shutdown"}
    proc tag {txt} {return "<$txt> -- tag (aka goto label)"}
    proc signature {txt name} {
        if {![string length $name]} {
            return {{Subprogram can't be anonymous} {} {}}
        }

        set a {}
        set r {}
        set d {}
        set w {}
        set visibility ""
        foreach l [split [regsub -all -line -- {--.*} $txt ""] "\n"] {
            set l [string trim $l]
            switch -glob $l {
                {}           {}
                {return *}   {lappend r " $l"}
                {declare *}  {lappend d "[string range $l 7 end];"}
                {use *}      {lappend d "$l;"}
                {with *}     {lappend w [string range $l 4 end]}
                {separate}   {set visibility "external"}
                default      {lappend a $l}
            }
        }
        set args_text [join $a "; "]
        if {[llength $a]} {
            set args_text "\($args_text\)"
        }

        set type "procedure"
        if {[llength $r]} {
            set type "function"
        }
        set with_string ""
        if {[llength $w]} {
            set with_string "with [join $w ","]"
        }
        set ret [list {} "$visibility\n$type $name$args_text[lindex $r 0]\n$with_string\n[join $d "\n"]"]
        return $ret
    }

    namespace export signature assign compare and not or shelf

    proc make_callbacks {} {
        set callback_names {
            and assign bad_case block_close body case_else case_end native_foreach
            case_value change_state comment compare continue declare
            elseif_start else_start for_check for_current for_declare for_incr
            for_init fsm_merge goto if_end if_start not or pass return_none
            select select_end shelf shutdown signature tag while_start body_end
        }
        set c {}
        foreach {a} $callback_names {
            gen::put_callback c $a gen_ada::$a
        }
        gen::put_callback c break "exit; -- break"
        return $c
    }

    proc highlight {tokens} {
        return [gen_cs::highlight_generic {
            abort else new return abs elsif not reverse abstract end null accept
            entry select access exception of separate aliased exit or some all
            others subtype and for out synchronized array function overriding at
            tagged generic package task begin goto pragma terminate body private
            then if procedure type case in protected constant interface until is
            raise use declare range delay limited record when delta loop rem
            while digits renames with do mod requeue xor} $tokens]
    }

    proc generate {db gdb filename} {
        set callbacks [make_callbacks]
        gen::fix_graph $gdb $callbacks 1
        lassign [gen::scan_file_description $db {spec_header spec_footer impl_header impl_footer}] sh sf bh bf
        set functions [gen::generate_functions $db $gdb $callbacks 1]
        if {[graph::errors_occured]} {
            error "Found errors"
        }
        try {
            set f [open_output_file [replace_extension $filename "adb"]]
            puts $f "-- Generated by DRAKON Editor [version_string]+\n"
            puts $f $bh
            print_forward_declarations $f $functions
            print_to_file $f $functions
            puts $f $bf
        } finally {
            close $f
        }
        try {
            set f [open_output_file [replace_extension $filename "ads"]]
            puts $f "-- Generated by DRAKON Editor [version_string]+\n"
            puts $f $sh
            print_exported_declarations $f $functions
            puts $f $sf
        } finally {
            close $f
        }

    }

    proc print_exported_declarations {fh functions} {
        foreach f $functions {
            lassign $f diagram_id name func_description body
            lassign [split $func_description "\n"] visibility signature aspect
            if {$visibility == "external"} {
                puts $fh "    $signature $aspect;"
            }
        }
    }

    proc print_forward_declarations {fh functions} {
        foreach f $functions {
            lassign $f diagram_id name func_description body
            lassign [split $func_description "\n"] visibility signature aspect
            if {[string length $visibility] == 0} {
                puts $fh "    $signature $aspect;"
            }
        }
    }

    proc print_to_file {fhandle functions} {
        foreach function $functions {
            lassign $function diagram_id name func_description body
            puts $fhandle ""
            set declarations [lassign [split $func_description "\n"] visibility signature aspect]
            puts $fhandle "$signature is\n[join $declarations "\n"]\nbegin"
            set lines [gen::indent $body 1]
            puts $fhandle $lines
            puts $fhandle "end $name;"
        }
    }

}
