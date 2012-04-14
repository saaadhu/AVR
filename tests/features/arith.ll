define i8 @main()
{
	%x = call i8 @add_fn(i8 2, i8 3);
	%y = call i8 @sub_fn(i8 3, i8 2);
	ret i8 %y;
}

define i8 @add_fn(i8 %a, i8 %b)
{
	%sum = add i8 %a, %b;
	ret i8 %sum;
}

define i8 @sub_fn(i8 %a, i8 %b)
{
	%diff = sub i8 %a, %b;
	ret i8 %diff;
}
