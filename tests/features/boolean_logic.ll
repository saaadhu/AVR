define i8 @main()
{
  %x1 = call i8 @and_func(i8 15,i8 8);
  %x2 = call i8 @or_func(i8 1,i8 2);
  %x3 = call i8 @xor_func(i8 1, i8 3);

  %x4 = and i8 %x3, 10;
  %x5 = or i8 %x4, 4;
  %x6 = xor i8 %x5, 1;
  %x7 = add i8 %x6, 99;

  ret i8 %x7;
}

define i8 @and_func(i8 %t1, i8 %t2)
{
  %res = and i8 %t1, %t2;
  ret i8 %res;
}

define i8 @or_func(i8 %t1, i8 %t2)
{
  %res = or i8 %t1, %t2;
  ret i8 %res;
}

define i8 @xor_func(i8 %t1, i8 %t2)
{
  %res = xor i8 %t1, %t2;
  ret i8 %res;
}

