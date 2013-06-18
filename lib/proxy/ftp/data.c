/*
 * ProFTPD - mod_proxy FTP data conn routines
 * Copyright (c) 2012-2013 TJ Saunders
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Suite 500, Boston, MA 02110-1335, USA.
 *
 * As a special exemption, TJ Saunders and other respective copyright holders
 * give permission to link this program with OpenSSL, and distribute the
 * resulting executable, without including the source code for OpenSSL in the
 * source distribution.
 */

#include "mod_proxy.h"
#include "proxy/ftp/buffer.h"
#include "proxy/ftp/data.h"

static const char *trace_channel = "proxy.ftp.data";

pr_buffer_t *proxy_ftp_data_recv(pool *p, conn_t *data_conn) {
  int nread;
  pr_buffer_t *pbuf = NULL;

  if (data_conn->instrm->strm_buf != NULL) {
    pbuf = data_conn->instrm->strm_buf;

  } else {
    pbuf = proxy_ftp_buffer_alloc(data_conn->instrm);
  }

  nread = pr_netio_read(data_conn->instrm, pbuf->buf, pbuf->buflen, 1);
  if (nread <= 0) {
    return NULL;
  }

  /* XXX Reset TimeoutIdle timer, TimeoutNoTransfer timer.  Are there
   * separate versions of these timers for frontend, backend?
   */

  pr_event_generate("mod_proxy.data-read", pbuf);
  pr_trace_msg(trace_channel, 15, "%.*s", nread, pbuf->buf);

  return pbuf;
}

int proxy_ftp_data_send(pool *p, conn_t *data_conn, pr_buffer_t *pbuf) {
  int nwrote;

  pr_event_generate("mod_proxy.data-read", pbuf);

  nwrote = pr_netio_write(data_conn->outstrm, pbuf->current, pbuf->remaining);
  while (nwrote < 0) {
    int xerrno = errno;

    if (xerrno == EAGAIN) {
      /* Since our socket is in non-blocking mode, write(2) can return
       * EAGAIN if there is not enough from for our data yet.  Handle
       * this by delaying temporarily, then trying again.
       */
      errno = EINTR;
      pr_signals_handle();

      nwrote = pr_netio_write(data_conn->outstrm, pbuf->current,
        pbuf->remaining);
      continue;
    }
  }

  /* XXX Reset TimeoutIdle timer, TimeoutNoTransfer timer.  Are there
   * separate versions of these timers for frontend, backend?
   */

  return nwrote;
}