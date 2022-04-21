# Browser Handling of DASH Event Messages

The aim of this proposal is to define browser-native handling of MPEG-DASH timed metadata events, which today is handled at the web application layer. MPEG DASH `emsg` events are included in MPEG CMAF, which has emerged as the common media delivery format in HLS and MPEG-DASH.

The current approach for handling in-band event information, implemented by libraries such as [dash.js](https://github.com/Dash-Industry-Forum/dash.js/wiki) and [hls.js](https://github.com/video-dev/hls.js), is to parse the media segments in JavaScript to extract the events and construct `VTTCue` objects.

On resource constrained devices such as smart TVs and streaming sticks, this leads to a significant performance penalty, which can have an impact on UI rendering updates if this is done on the UI thread (although we note the [proposal](https://github.com/wicg/media-source/blob/mse-in-workers-using-handle/mse-in-workers-using-handle-explainer.md) to make Media Source Extensions available to Worker contexts). There can also be an impact on the battery life of mobile devices. Given that the media segments will be parsed anyway by the user agent, parsing in JavaScript is an expensive overhead that could be avoided.

Avoiding parsing in JavaScript is also important for low latency video streaming applications, where minimizing the time taken to pass media content through to the media element's playback buffer is essential.

Instead of using `VTTCue`, a separate proposal introduces `DataCue` as a more appropriate cue API for timed metadata. See the [DataCue explainer](explaner.md) for details.

## Use cases

Many of the use cases are described in the [DataCue explainer](explainer.md).

### Dynamic content insertion

A media content provider wants to allow insertion of content, such as personalised video, local news, or advertisements, into a video media stream that contains the main program content. To achieve this, timed metadata is used to describe the points on the media timeline, known as splice points, where switching playback to inserted content is possible.

[SCTE 35](https://scte-cms-resource-storage.s3.amazonaws.com/ANSI_SCTE-35-2019a-1582645390859.pdf) defines a data cue format for describing such insertion points. Use of these cues in MPEG-DASH streams is described in [SCTE 214-1](https://scte-cms-resource-storage.s3.amazonaws.com/Standards/ANSI_SCTE%20214-1%202016.pdf), [SCTE 214-2](https://scte-cms-resource-storage.s3.amazonaws.com/Standards/ANSI_SCTE%20214-2%202016.pdf), and [SCTE 214-3](https://scte-cms-resource-storage.s3.amazonaws.com/Standards/ANSI_SCTE%20214-3%202015.pdf). Use in HLS streams is described in SCTE-35 section 12.2.

### Media player control messages

MPEG-DASH defines several control messages for media streaming clients (e.g., libraries such as [dash.js](https://github.com/Dash-Industry-Forum/dash.js/wiki)). Control messages exist for several scenarios, such as:

* The media player should refresh or update its copy of the manifest document (MPD)
* The media player should make an HTTP request to a given URL for analytics purposes
* The media presentation will end at a time earlier than expected

These messages may be carried as in-band `emsg` events in the media container files.

## Proposed API

The proposed API is based on the existing [text track support](https://html.spec.whatwg.org/multipage/media.html#timed-text-tracks) in HTML and the [proposed `DataCue` API](explainer.md).

> TODO: Add API summary

As new `emsg` event types can be introduced from time to time, we propose to expose the raw binary `emsg` data for applications to parse. This avoids the need for browsers to natively understand the structure of the event messages.

We will need to specify how to extract in-band timed metadata from the media container, and the structure in which the data is exposed via the `DataCue` interface. There are a couple of options for how to do this:

1. We could update the existing [Sourcing In-band Media Resource Tracks from Media Containers into HTML](https://dev.w3.org/html5/html-sourcing-inband-tracks/) spec.

2. We could produce a new set of specifications, following a registry approach with one specification per media format that describes the timed metadata details for that format, similar to the [Media Source Extensions Byte Stream Format Registry](https://www.w3.org/TR/mse-byte-stream-format-registry/). This could be based on [Sourcing In-band Media Resource Tracks from Media Containers into HTML](https://dev.w3.org/html5/html-sourcing-inband-tracks/).

## Code examples

> TODO: Needs updating: show how to subscribe to specific event streams, show how to set the dispatch mode.

### Subscribing to receive in-band timed metadata cues

This example shows how to add a `cuechange` handler that can be used to receive media-timed data and event cues.

```javascript
const video = document.getElementById('video');

video.textTracks.addEventListener('addtrack', (event) => {
  const textTrack = event.track;

  if (textTrack.kind === 'metadata') {
    textTrack.mode = 'hidden';

    // See cueChangeHandler examples below
    textTrack.addEventListener('cuechange', cueChangeHandler);
  }
});
```

### MPEG-DASH callback event handler

```javascript
const cueChangeHandler = (event) => {
  const metadataTrack = event.target;
  const activeCues = metadataTrack.activeCues;

  for (let i = 0; i < activeCues.length; i++) {
    const cue = activeCues[i];

    // The UA delivers parsed message data for this message type
    if (cue.type === 'urn:mpeg:dash:event:callback:2015' &&
        cue.value.emsgValue === '1') {
      const url = cue.value.data;
      fetch(url).then(() => { console.log('Callback completed'); });
    }
  }
};
```

### SCTE-35 dynamic content insertion cue handler

This example shows how a web application can handle [SCTE 35](https://scte-cms-resource-storage.s3.amazonaws.com/Standards/ANSI_SCTE%20214-3%202015.pdf) cues, both in the case where the cues are parsed by the browser implementation, and where parsed by the web application.

```javascript
const cueChangeHandler = (event) => {
  const metadataTrack = event.target;
  const activeCues = metadataTrack.activeCues;

  for (let i = 0; i < activeCues.length; i++) {
    const cue = activeCues[i];

    if (cue.type === 'urn:scte:scte35:2013:bin') {
      // Parse the SCTE-35 message payload.
      // parseSCTE35Data() is similar to Comcast's scte35.js library,
      // adapted to take an ArrayBuffer as input.
      // https://github.com/Comcast/scte35-js/blob/master/src/scte35.ts
      const scte35Message = parseSCTE35Data(cue.value.data);

      console.log(cue.startTime, cue.endTime, scte35Message.tableId, scte35Message.spliceCommandType);
    }
  }
};
```

### Cue enter/exit handlers

This example shows how a web application can use the proposed new `addcue` event to attach `enter` and `exit` handlers to each cue on the metadata track.

```javascript
// video.currentTime has reached the cue start time
// through normal playback progression
const cueEnterHandler = (event) => {
  const cue = event.target;
  console.log('cueEnter', cue.startTime, cue.endTime);
};

// video.currentTime has reached the cue end time
// through normal playback progression
const cueExitHandler = (event) => {
  const cue = event.target;
  console.log('cueExit', cue.startTime, cue.endTime);
};

// A cue has been parsed from the media container
const addCueHandler = (event) => {
  const cue = event.cue;

  // Attach enter/exit event handlers
  cue.onenter = cueEnterhandler;
  cue.onexit = cueExitHandler;
};

const video = document.getElementById('video');

video.textTracks.addEventListener('addtrack', (event) => {
  const textTrack = event.track;

  if (textTrack.kind === 'metadata') {
    textTrack.mode = 'hidden';

    textTrack.addEventListener('addcue', addCueHandler);
  }
});
```

## Considered alternatives

> TODO

## References

This explainer is based on content from a [Note](https://w3c.github.io/me-media-timed-events/) written by the W3C Media and Entertainment Interest Group, and from a number of associated discussions, including the [TPAC breakout session on video metadata cues](https://github.com/w3c/strategy/issues/113#issuecomment-432971265). It is also closely related to the DASH-IF [DASH Player's Application Events and Timed Metadata Processing Models and APIs](https://dashif-documents.azurewebsites.net/Events/master/event.html) document.
