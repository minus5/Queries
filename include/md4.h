#ifndef MD4_H
#define MD4_H

/* $Id: md4.h,v 1.8 2009/01/16 20:27:56 jklowden Exp $ */

#if defined(__GNUC__) && __GNUC__ >= 4
#pragma GCC visibility push(hidden)
#endif

struct MD4Context
{
	TDS_UINT buf[4];
	TDS_UINT bits[2];
	unsigned char in[64];
};

void MD4Init(struct MD4Context *context);
void MD4Update(struct MD4Context *context, unsigned char const *buf, size_t len);
void MD4Final(struct MD4Context *context, unsigned char *digest);
void MD4Transform(TDS_UINT buf[4], TDS_UINT const in[16]);

typedef struct MD4Context MD4_CTX;

#if defined(__GNUC__) && __GNUC__ >= 4
#pragma GCC visibility pop
#endif

#endif /* !MD4_H */
