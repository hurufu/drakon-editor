.PHONY: prove index clean run tests

vpath %.tcl ..

run: obj/demo
	./$<
prove: obj/gnatprove/gnatprove.out
	cat $<
clean: R := obj example.adb example.ads tags
clean:
	$(let f,$(strip $(wildcard $R)),$(if $f,$(RM) -r -- $f,))
index: tags
tests: ut/all.tcl $(wildcard ut/*.test)
	tclsh $< -testdir ut

obj/demo: main.gpr spark.adc example.adb example.ads demo.adb
	gprbuild -P $< -s
obj/gnatprove/gnatprove.out: main.gpr spark.adc example.adb
	gnatprove -P $< --mode=gold --level=4
%.ads %.adb: %.drn drakon_gen.tcl ada.tcl
	$(word 2,$^) -in $<
tags: drakon_gen.tcl ada.tcl demo.adb
	ctags -f $@ -R ..
