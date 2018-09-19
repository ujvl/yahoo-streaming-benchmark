package flink.benchmark.generator;

import flink.benchmark.BenchmarkConfig;

import java.util.*;

/**
 * A data generator source
 */
public class NoJSONEventGeneratorSource extends LoadGeneratorSource<NoJSONEvent> {

  private int adsIdx = 0;
  private int eventsIdx = 0;
  private StringBuilder sb = new StringBuilder();
  private String pageID = UUID.randomUUID().toString();
  private String userID = UUID.randomUUID().toString();
  private final String[] eventTypes = new String[]{ "view", "click", "purchase" };

  private List<String> ads;
  private final Map<String, List<String>> campaigns;

  public NoJSONEventGeneratorSource(BenchmarkConfig config) {
    super(config.loadTargetHz, config.timeSliceLengthMs);
    this.campaigns = generateCampaigns();
    this.ads = flattenCampaigns();
  }

  public Map<String, List<String>> getCampaigns() {
    return campaigns;
  }

  /**
   * Generate a single element
   */
  @Override
  public NoJSONEvent generateElement(long timeWindow) {
    if (adsIdx == ads.size()) {
      adsIdx = 0;
    }
    if (eventsIdx == eventTypes.length) {
      eventsIdx = 0;
    }
    NoJSONEvent e = new NoJSONEvent();
    e.userId = userID;
    e.pageId = pageID;
    e.adId = ads.get(adsIdx++);
    e.adType = "banner78";
    e.eventType = eventTypes[eventsIdx++];
    e.eventTime =  Long.toString(timeWindow);
    e.ipAddress = "1.2.3.4";
    return e;
  }

  /**
   * Generate a random list of ads and campaigns
   */
  private Map<String, List<String>> generateCampaigns() {
    int numCampaigns = 100;
    int numAdsPerCampaign = 10;
    Map<String, List<String>> adsByCampaign = new LinkedHashMap<>();
    for (int i = 0; i < numCampaigns; i++) {
      String campaign = UUID.randomUUID().toString();
      ArrayList<String> ads = new ArrayList<>();
      adsByCampaign.put(campaign, ads);
      for (int j = 0; j < numAdsPerCampaign; j++) {
        ads.add(UUID.randomUUID().toString());
      }
    }
    return adsByCampaign;
  }

  /**
   * Flatten into just ads
   */
  private List<String> flattenCampaigns() {
    // Flatten campaigns into simple list of ads
    List<String> ads = new ArrayList<>();
    for (Map.Entry<String, List<String>> entry : campaigns.entrySet()) {
      for (String ad : entry.getValue()) {
        ads.add(ad);
      }
    }
    return ads;
  }
}
