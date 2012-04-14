define i8 @main()
{
	%x = alloca i8;
	%y = alloca i8;

	store i8 1, i8* %x;
	store i8 2, i8* %y;

	%x_val = load i8* %x;
	%y_val = load i8* %y;

	ret i8 %x_val;
}
