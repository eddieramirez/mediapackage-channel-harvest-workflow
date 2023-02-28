
export async function handler(event, context) {
    console.log(event);
    const harvestJobType = event.harvestJobType;
    const channelConfiguration = event.channelConfiguration;
    const channelInformation = event.channelInformation;
    const bucketInformation = event.bucketInformation;
    const eventTime = event.time;
    const harvestJobStartTime = new Date(eventTime);
    const harvestJobStopTime = new Date(eventTime);
    const timeYear= harvestJobStartTime.getFullYear();
    const timeMonth = String(harvestJobStartTime.getMonth() + 1).padStart(2, '0');
    const timeDay = String(harvestJobStartTime.getDate()).padStart(2, '0');
    const timeHour = String(harvestJobStartTime.getHours()).padStart(2, '0');
    const timePath = `${timeYear}/${timeMonth}/${timeDay}/${timeHour}`;
    const timeString = `${timeYear}${timeMonth}${timeDay}${timeHour}`;

    let harvestId;
    let harvestChannelName;
    let harvestMediapackageChannelId;
    let harvestMediapackageOriginEndpointId;
    let harvestkey;

    if(harvestJobType == 'hourly') {
        console.log('hourly harvest job');
        harvestJobStartTime.setHours(harvestJobStartTime.getHours() - 1);
        harvestChannelName = channelInformation.channelName;
        harvestMediapackageChannelId = channelInformation.mediapackageChannelId;
        harvestMediapackageOriginEndpointId = channelInformation.mediapackageOriginEndpointId;

        harvestkey = `${bucketInformation.prefix}/${harvestChannelName}/${timePath}/${harvestChannelName}_${timeString}_index.m3u8`;
        harvestId = `${harvestChannelName}-${timeString}-hourly`;
    } else if (harvestJobType == 'adhoc') {
        console.log('adhoc harvest job');
        harvestJobStartTime.setMinutes(0);
        harvestJobStartTime.setSeconds(0);

        const emlChannelId = channelInformation.channel_arn.split(':').pop();
        const adhocChannelconfiguration = channelConfiguration.find(({ medialiveChannelId }) => medialiveChannelId === emlChannelId);
        if (!adhocChannelconfiguration) {
          console.log("channel is not in channel configuration")
          const filterException = {
            filterException: "channel is not in channel configuration"
          };
          return filterException;
        }
        harvestChannelName = adhocChannelconfiguration.channelName;
        harvestMediapackageChannelId = adhocChannelconfiguration.mediapackageChannelId;
        harvestMediapackageOriginEndpointId = adhocChannelconfiguration.mediapackageOriginEndpointId;

        harvestkey = `${bucketInformation.prefix}/${harvestChannelName}/${timePath}/${harvestChannelName}_${timeString}_index.m3u8`;
        harvestId = `${harvestChannelName}-${timeString}-adhoc`;

    } else {
        throw new Error('unidentified job type');
    }

    let harvestJobConfiguration = {
        harvestId: harvestId,
        harvestBucket: bucketInformation.bucket,
        harvestKey: harvestkey,
        startTime: harvestJobStartTime,
        endTime: harvestJobStopTime,
        mediapackageChannelId: harvestMediapackageChannelId,
        mediapackageOriginEndpointId: harvestMediapackageOriginEndpointId,
    };
    console.log(harvestJobConfiguration);
    return  harvestJobConfiguration;
}
