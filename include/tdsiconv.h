/* FreeTDS - Library of routines accessing Sybase and Microsoft databases
 * Copyright (C) 2002, 2003, 2004  Brian Bruns
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#ifndef _tds_iconv_h_
#define _tds_iconv_h_

/* $Id: tdsiconv.h,v 1.37 2008/10/17 08:39:16 freddy77 Exp $ */

#if HAVE_ICONV
#include <iconv.h>
#else
/* Define iconv_t for src/replacements/iconv.c. */
#undef iconv_t
typedef void *iconv_t;
#endif /* HAVE_ICONV */

#if HAVE_ERRNO_H
#include <errno.h>
#endif

#if HAVE_WCHAR_H
#include <wchar.h>
#endif

/* The following EILSEQ advice is borrowed verbatim from GNU iconv.  */
/* Some systems, like SunOS 4, don't have EILSEQ. Some systems, like BSD/OS,
   have EILSEQ in a different header.  On these systems, define EILSEQ
   ourselves. */
#ifndef EILSEQ
# define EILSEQ ENOENT
#endif

#if HAVE_STDLIB_H
#include <stdlib.h>
#endif /* HAVE_STDLIB_H */

#if defined(__GNUC__) && __GNUC__ >= 4
#pragma GCC visibility push(hidden)
#endif

#ifdef __cplusplus
extern "C"
{
#endif

#if ! HAVE_ICONV

	/* FYI, the first 4 entries look like this:
	 *      {"ISO-8859-1",  1, 1}, -> 0
	 *      {"US-ASCII",    1, 4}, -> 1
	 *      {"UCS-2LE",     2, 2}, -> 2
	 *      {"UCS-2BE",     2, 2}, -> 3
	 *
	 * These conversions are supplied by src/replacements/iconv.c for the sake of those who don't 
	 * have or otherwise need an iconv.
	 */
enum ICONV_CD_VALUE
{
	  Like_to_Like = 0x100
	, Latin1_ASCII  = 0x01
	, ASCII_Latin1  = 0x10

	, Latin1_UCS2LE = 0x02
	, UCS2LE_Latin1 = 0x20
	, ASCII_UCS2LE  = 0x12
	, UCS2LE_ASCII  = 0x21

	, Latin1_UTF8	= 0x03
	, UTF8_Latin1	= 0x30
	, ASCII_UTF8	= 0x13
	, UTF8_ASCII	= 0x31
	, UCS2LE_UTF8	= 0x23
	, UTF8_UCS2LE	= 0x32

#ifdef DOS32X
	, WinEE_UCS2LE  = 0x42
	, UCS2LE_WinEE  = 0x24
	, WinCYR_UCS2LE = 0x52
	, UCS2LE_WinCYR = 0x25
	, WinTUR_UCS2LE = 0x62
	, UCS2LE_WinTUR = 0x26
	, WinARA_UCS2LE = 0x72
	, UCS2LE_WinARA = 0x27
#endif
	/* these aren't needed 
	 * , Latin1_UCS2BE = 0x03
	 * , UCS2BE_Latin1 = 0x30
	 */
};

iconv_t tds_sys_iconv_open(const char *tocode, const char *fromcode);
size_t tds_sys_iconv(iconv_t cd, const char **inbuf, size_t * inbytesleft, char **outbuf, size_t * outbytesleft);
int tds_sys_iconv_close(iconv_t cd);
#else
#define tds_sys_iconv_open iconv_open
#define tds_sys_iconv iconv
#define tds_sys_iconv_close iconv_close
#endif /* !HAVE_ICONV */


typedef enum
{ to_server, to_client } TDS_ICONV_DIRECTION;

typedef struct _character_set_alias
{
	const char *alias;
	int canonic;
} CHARACTER_SET_ALIAS;

typedef struct _tds_errno_message_flags {
	unsigned int e2big:1;
	unsigned int eilseq:1;
	unsigned int einval:1;
} TDS_ERRNO_MESSAGE_FLAGS;

struct tdsiconvinfo
{
	TDS_ENCODING client_charset;
	TDS_ENCODING server_charset;

#define TDS_ENCODING_INDIRECT 1
#define TDS_ENCODING_SWAPBYTE 2
#define TDS_ENCODING_MEMCPY   4
	unsigned int flags;

	iconv_t to_wire;	/* conversion from client charset to server's format */
	iconv_t from_wire;	/* conversion from server's format to client charset */

	iconv_t to_wire2;	/* conversion from client charset to server's format - indirect */
	iconv_t from_wire2;	/* conversion from server's format to client charset - indirect */
	
	/* 
	 * Suppress error messages that would otherwise be emitted by tds_iconv().
	 * Functions that process large buffers ask tds_iconv to convert it in "chunks".
	 * We don't want to emit spurious EILSEQ errors or multiple errors for one 
	 * buffer.  tds_iconv() checks this structure before emiting a message, and 
	 * adds to it whenever it emits one.  Callers that handle a particular situation themselves
	 * can prepopulate it.  
	 */ 
	TDS_ERRNO_MESSAGE_FLAGS suppress;
};

/* We use ICONV_CONST for tds_iconv(), even if we don't have iconv() */
#ifndef ICONV_CONST
# define ICONV_CONST const
#endif

size_t tds_iconv_fread(iconv_t cd, FILE * stream, size_t field_len, size_t term_len, char *outbuf, size_t * outbytesleft);
size_t tds_iconv(TDSSOCKET * tds, const TDSICONV * char_conv, TDS_ICONV_DIRECTION io,
		 const char **inbuf, size_t * inbytesleft, char **outbuf, size_t * outbytesleft);
const char *tds_canonical_charset_name(const char *charset_name);
const char *tds_sybase_charset_name(const char *charset_name);
TDSICONV *tds_iconv_get(TDSSOCKET * tds, const char *client_charset, const char *server_charset);

#ifdef __cplusplus
}
#endif

#if defined(__GNUC__) && __GNUC__ >= 4
#pragma GCC visibility pop
#endif

#endif /* _tds_iconv_h_ */
