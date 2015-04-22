/*
 * Copyright (c) 2007, Swedish Institute of Computer Science.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the Institute nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE INSTITUTE AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE INSTITUTE OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * This file is part of the Contiki operating system.
 *
 */

/**
 * \file
 *         Testing the broadcast layer in Rime
 * \author
 *         Adam Dunkels <adam@sics.se>
 */

#include "contiki.h"
#include "net/rime.h"
#include "random.h"

#include "dev/button-sensor.h"

#include "dev/leds.h"

#include <stdio.h>

#include <math.h> // for square root -hxiong

#define INITIAL_STD 10000
/*---------------------------------------------------------------------------*/
PROCESS(example_broadcast_process, "Broadcast example");
AUTOSTART_PROCESSES(&example_broadcast_process);
/*---------------------------------------------------------------------------*/
/*****  RSSI PACKET FORMAT -hxiong *******/
/* First number: ATTRIBUTE: 0 means Unknown, 1 means beacon.
 * Second number: x position
 * Third number: y position
 * Fourth number: std                   */
static float rssi_pkt_buf[4]={0,50,50,INITIAL_STD};
static float neighbor_attr = 0;
static float neighbor_x = 0;
static float neighbor_y = 0;
static float neighbor_std = 0;
static float neighbor_dis = 0;
static float neighbor_dis_std = 0;
static int neighbor_rssi = 0;
static float tmp = 0;
static void kick_loc();
static void kick_cal();
static float my_sqrt(const float x);
static float my_sqrt2(const float number);
// calibrated rssi_distance mapping from -42 to -87 dBm. The mapping between rssi value and array index is: index = -RSSI -42.
static struct RSSI_DIS_MEAN_STD
{
	float mean;
	float std;
}mean_std_array[46] = {
						{0.20,0}, // -42
						{0.37,0.20}, // -43
						{0.38,0.10}, // -44
						{0.40,0}, // -45
						{0.21,0.05}, // -46
						{0.79,0.06}, // -47
						{0.41,0.07}, // -48
						{0.20,0}, // -49
						{0.35,0.05}, // -50
						{0.50,0.10}, // -51
						{0.4,0}, // -52
						{0.4,0}, // -53
						{0.65,0.12}, // -54
						{0.89,0.25}, // -55
						{1.29,0.29}, // -56
						{1.12,0.22}, // -57
						{1.29,0.48}, // -58
						{1.37,0.40}, // -59
						{1.48,0.35}, // -60
						{1.40,0.79}, // -61
						{2.21,0.50}, // -62
						{2.12,0.64}, // -63
						{2.07,0.65}, // -64
						{2.07,6.61}, // -65
						{2.16,0.57}, // -66
						{2.21,0.46}, // -67
						{2.12,0.61}, // -68
						{2.17,0.61}, // -69
						{2.32,0.44}, // -70
						{2.51,0.27}, // -71
						{2.62,0.21}, // -72
						{2.70,0.17}, // -73
						{2.65,0.33}, // -74
						{2.30,0.50}, // -75
						{2.59,0.19}, // -76
						{2.63,0.19}, // -77
						{2.66,0.20}, // -78
						{2.64,0.23}, // -79
						{2.61,0.23}, // -80
						{2.61,0.23}, // -81
						{2.50,0.18}, // -82
						{2.44,0.14}, // -83
						{2.44,0.15}, // -84
						{2.42,0.10}, // -85
						{2.60,0.31}, // -86
						{3.00,0.00}, // -87
};
static void
broadcast_recv(struct broadcast_conn *c, const rimeaddr_t *from)
{
	neighbor_rssi = packetbuf_attr(PACKETBUF_ATTR_RSSI);
	/* if rssi out of calibration range, treat it as boundary values.*/
    if (neighbor_rssi < -42)
	{
		neighbor_rssi = -42;
	}
	if (neighbor_rssi > -87)
	{
		neighbor_rssi = -87;
	}

	neighbor_dis = mean_std_array[-neighbor_rssi-42].mean; // need a mapping function
	neighbor_dis_std = mean_std_array[-neighbor_rssi-42].std; // need a look up table
	neighbor_attr = *(float *)packetbuf_dataptr();
    neighbor_x = *((float *)packetbuf_dataptr()+1);
	neighbor_y = *((float *)packetbuf_dataptr()+2);
	neighbor_std = *((float *)packetbuf_dataptr()+3);
	printf("neighbor_x: %f, neighbor_y: %f \n",neighbor_x, neighbor_y);
	//printf("attr=%f,x=%f,y=%f, std=%f\n",neighbor_attr, neighbor_x, neighbor_y, neighbor_std);

//  printf("broadcast message received from %d.%d: '%s', rssi=%d\n",
//         from->u8[0], from->u8[1], (char *)packetbuf_dataptr(), packetbuf_attr(PACKETBUF_ATTR_RSSI));
	//printf("***************\n");
//	printf("tmp: %f\n",tmp);
//	printf("Tx ID: %d.%d\nRx ID: %d.%d\nType: %f\nPos: %f,%f\nSTD:%f\nrssi: %d\n",
//			from->u8[0], from->u8[1],rimeaddr_node_addr.u8[0],rimeaddr_node_addr.u8[1],*(double *)packetbuf_dataptr(),*((double *)packetbuf_dataptr()+1),*((double *)packetbuf_dataptr()+2),*((double *)packetbuf_dataptr()+3),packetbuf_attr(PACKETBUF_ATTR_RSSI));
	kick_loc();
	printf("After received packet from %d.%d, RSSI = %d\n",from->u8[0], from->u8[1],packetbuf_attr(PACKETBUF_ATTR_RSSI));
	printf("Updated estimate: (%f,%f), std: %f\n", (float )rssi_pkt_buf[1],(float )rssi_pkt_buf[2],(float )rssi_pkt_buf[3]);
}

static void 
kick_loc()
{
	float before_sqrt = 0.0;
	//printf("Enter kick_loc...\n");
	if (rssi_pkt_buf[3] == INITIAL_STD){
		// I don't have estimate yet
		if (neighbor_std != INITIAL_STD){
			// neighbor has estimate, I'll update x,y,std accordingly.
		//	printf("here");
			rssi_pkt_buf[1] = neighbor_x;
			rssi_pkt_buf[2] = neighbor_y;
			before_sqrt = neighbor_std*neighbor_std + neighbor_dis*neighbor_dis + neighbor_dis_std*neighbor_dis_std;
			rssi_pkt_buf[3] = my_sqrt2(neighbor_std*neighbor_std + neighbor_dis*neighbor_dis + neighbor_dis_std*neighbor_dis_std);
		}
			// neighbor also doesn't have estimate yet, do nothing.
	}
	
	else{
		if ((neighbor_std == INITIAL_STD) || (rssi_pkt_buf[1] == neighbor_x && rssi_pkt_buf[2] == neighbor_y))
		   // if neighbor also has no est, or neighbor and I have same est, do nothing.
			;	
		else
			kick_cal(); // call kick_cal to update the est.
				
	}	
	
	
//	else {
		// 
//	}

}

/* calculate the kick */
static void kick_cal()
{
	float est_d,delta_d_x,delta_d_y,std_update,alpha;
	// calculate est_d
	est_d = (rssi_pkt_buf[1] - neighbor_x)*(rssi_pkt_buf[1] - neighbor_x) + (rssi_pkt_buf[2] - neighbor_y)*(rssi_pkt_buf[2] - neighbor_y);
	est_d = my_sqrt2(est_d);
	// calculate delta_d
	delta_d_x = (est_d - neighbor_dis) * (neighbor_x - rssi_pkt_buf[1])/est_d;
	delta_d_y = (est_d - neighbor_dis) * (neighbor_y - rssi_pkt_buf[2])/est_d;
    // calculate the std of the update
	std_update = my_sqrt2(neighbor_dis_std*neighbor_dis_std + neighbor_std*neighbor_std);
	// calculate the alpha factor
	alpha = rssi_pkt_buf[3]/(rssi_pkt_buf[3] + std_update);
	// update the est_std
	rssi_pkt_buf[3] = alpha * std_update + (1 - alpha) * rssi_pkt_buf[3];
	// update the est
	rssi_pkt_buf[1] = rssi_pkt_buf[1] + alpha * delta_d_x;
	rssi_pkt_buf[2] = rssi_pkt_buf[2] + alpha * delta_d_y;

}

static float my_sqrt2(const float number)
{
	
	const float ACCURACY=0.001;
	float lower, upper, guess;

	if (number < 1)
	{
		lower = number;
		upper = 1;
	}
	else
	{
		lower = 1;
		upper = number;
	}
    
	while ((upper-lower) > ACCURACY)
	{
		guess = (lower + upper)/2;
		if(guess*guess > number)
			upper =guess;
		else
			lower = guess; 
	}
	
	return (lower + upper)/2;
	
}  


static float my_sqrt(const float x)
{
	//printf("inside mysqrt\n");
	static union
	{
		int32_t i;
		float x;
	} u;
	u.x = x;
	u.i = (1<<29) + (u.i >> 1) - (1<<22);
	return u.x;
	// Two Babylonian Steps (simplified from:)
	// u.x = 0.5f * (u.x + x/u.x);
	// u.x = 0.5f * (u.x + x/u.x);
	//u.x = u.x + x/u.x;
	//u.x = 0.25f*u.x + x/u.x;
	//return u.x;

}

static const struct broadcast_callbacks broadcast_call = {broadcast_recv};
static struct broadcast_conn broadcast;
/*---------------------------------------------------------------------------*/
PROCESS_THREAD(example_broadcast_process, ev, data)
{
  static struct etimer et;
  PROCESS_EXITHANDLER(broadcast_close(&broadcast);)

  PROCESS_BEGIN();

  broadcast_open(&broadcast, 129, &broadcast_call);

  while(1) {
    etimer_set(&et, CLOCK_SECOND);
    PROCESS_WAIT_EVENT_UNTIL(etimer_expired(&et));
	packetbuf_copyfrom(rssi_pkt_buf, 4*sizeof(float));
    broadcast_send(&broadcast);
	//printf("broadcast msg sent\n");
  }
  PROCESS_END();
}
/*---------------------------------------------------------------------------*/
