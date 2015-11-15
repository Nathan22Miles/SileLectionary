int main()
{
   unsigned char sigbytes[4];
   png_sig_cmp (sigbytes, 0, sizeof(sigbytes));

	return 1;
}