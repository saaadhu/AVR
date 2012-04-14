define i8 @shr_func(i8 %t)
{
  %x = lshr i8 %t, 2;
  ret i8 %x;
}

define i8 @shl_func(i8 %t)
{
  %x = shl i8 %t, 2;
  ret i8 %x;
}

define i8 @shra_func(i8 %t)
{
  %x = ashr i8 %t, 2;
  ret i8 %x;
}

define i8 @main()
{
  %x = call i8 @shr_func(i8 20);
  %y = call i8 @shl_func(i8 20);
  %z = call i8 @shra_func(i8 20);
  ret i8 %z;
}
