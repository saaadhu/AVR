define void @main(i8 %a, i8 %b)
{
	br label %Begin;
	Begin:
	%cond = icmp eq i8 %a, %b;
	br i1 %cond, label %Equal, label %Not_equal;

	Equal:
		br label %Begin;
	Not_equal:
		br label %Begin;
	
	ret void;
}
