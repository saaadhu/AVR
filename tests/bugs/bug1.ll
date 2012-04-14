define i8 @func(i8 %p)
{
  ret i8 1;
}

define i8 @main(i8 %p)
{
  %x = alloca i8;
  store i8 %p, i8* %x;
  %y = load i8* %x;

  %f = call i8 @func(i8 %y);

  %t = add i8 %y, %f;
  ret i8 %t;
}
