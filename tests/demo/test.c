#define VPORT0_DIR *((char *)(char)16)
#define VPORT0_OUT *((char *)(char)17)

#define VPCTRL_A *((char *)(char)178)

void setup()
{
	 VPCTRL_A = 4; 
	 VPORT0_DIR = 255;
}

void setled(char status)
{
	VPORT0_OUT = status;
}

void act()
{
	volatile char t = 0;
	for (;t < 8; t++)
		setled(t);
}

void test()
{
	setup();
	setled(255);

}

