/**
 * Copyright 2015, Yahoo Inc.
 * Licensed under the terms of the Apache License 2.0. Please see LICENSE file in the project root for terms.
 */

package benchmark.common.advertising;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import redis.clients.jedis.Jedis;

import java.util.concurrent.ThreadLocalRandom;
import java.util.concurrent.TimeUnit;
import java.util.HashMap;

public class RedisAdCampaignCache {

    private Jedis jedis;
    private HashMap<String, String> ad_to_campaign;

    private static final Logger LOG = LoggerFactory.getLogger(RedisAdCampaignCache.class);

    public RedisAdCampaignCache(String redisServerHostname, int redisDb) {
        LOG.info("INITializinG RedisAdCampaignCache");

	LOG.info("Attempting to connect...");
	while (true) {
	    try {
		int ms = ThreadLocalRandom.current().nextInt(0, 100);
		LOG.info("Cache waiting to init... sleeping {}ms", ms);
		TimeUnit.MILLISECONDS.sleep(ms); 
	        jedis = new Jedis(redisServerHostname, 6379, 10000);
		break;
	    }
	    catch (Exception e) {
                LOG.info("Retrying...");
		continue;
	    }
	}
	LOG.info("Connected!");
	jedis.select(redisDb);

//	LOG.info("WRITE_TEST");
//	jedis.set("foo", "bar");
//	LOG.info("READ_TEST");
//        LOG.info("Get foo: {}", jedis.get("foo")); 
    }

    public RedisAdCampaignCache(String redisServerHostname) {
        jedis = new Jedis(redisServerHostname);
    }

    public void prepare() {
        ad_to_campaign = new HashMap<String, String>();
    }

    public String execute(String ad_id) {
        String campaign_id = ad_to_campaign.get(ad_id);
        if(campaign_id == null) {
            campaign_id = jedis.get(ad_id);
            if(campaign_id == null) {
                return null;
            }
            else {
                ad_to_campaign.put(ad_id, campaign_id);
            }
        }
        return campaign_id;
    }
}
