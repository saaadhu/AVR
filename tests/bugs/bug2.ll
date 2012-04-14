
define i8 @main(i8 %p)
{
  %x = alloca i8;
  store i8 %p, i8* %x;
  %y = load i8* %x;

  %t = add i8 %y, 3;
  ret i8 %t;
}
