define i8 @main()
{
	%vport0_dir = inttoptr i8 16 to i8*;
	%vport0_out = inttoptr i8 17 to i8*;

	;Map PORTE to VPORT0
	%vpctrla = inttoptr i8 178 to i8*;
	store i8 4, i8* %vpctrla;

	;Set all pins to output
	store i8 255, i8* %vport0_dir;

	;Turn on all the pins
	store i8 0, i8* %vport0_out;

	;Read the value of the port back
	%vport0_out_1 = inttoptr i8 19 to i8*;
	%x = load i8* %vport0_out_1;

	ret i8 %x;
}


