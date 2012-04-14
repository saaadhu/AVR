define i8 @main()
{
	call void @setup();

	%x = call i8 @test(i8 1, i8 1);

	br label %Loop;
    Loop:
	br label %Loop;
}

define void @setup()
{
	%vport0_dir = inttoptr i8 16 to i8*;

	;Map PORTE to VPORT0
	%vpctrla = inttoptr i8 178 to i8*;
	store i8 4, i8* %vpctrla;

	;Set all pins to output
	store i8 255, i8* %vport0_dir;

	ret void;
}

define void @set_leds(i8 %ledstatus)
{
	%vport0_out = inttoptr i8 17 to i8*;
	store i8 %ledstatus, i8* %vport0_out;
	ret void;
}


define i8 @test(i8 %a, i8 %b)
{
	%cond = icmp eq i8 %a, %b;
	br i1 %cond, label %Equal, label %Not_equal;

	Equal:
	   call void @set_leds(i8 240);
	   ret i8 1;
    Not_equal:
	   call void @set_leds(i8 15);
	   ret i8 2;
}

