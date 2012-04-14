define i8 @main()
{
	%x = call i8 @test(i8 1, i8 2);
	ret i8 %x;
}

define i8 @test(i8 %a, i8 %b)
{
	%cond = icmp eq i8 %a, %b;
	br i1 %cond, label %Equal, label %Not_equal;

	Equal:
	   ret i8 1;
    Not_equal:
	   ret i8 2;
}

