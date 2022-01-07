# Push notifications

Push notifications are sent via [Airship](https://www.airship.com), whose SDK is integrated into the Play SRG app. The SDK is currently only integrated for iOS only.

## Manually sending push notifications via Airship

1. Pick a show and an associated media and write down their URNs.
1. On a test device launch an **internal build** of the associated Play SRG application and register to push notifications for the show you picked.
1. Login to the [Airship](https://go.airship.com/accounts/login) administration interface.
1. Pick the project corresponding to the Play SRG application you are using.
1. Click the + button and choose _Message_. Then proceed through the required steps to create a realistic push notification:
    1. _Audience_: Either restrict to iOS or enable both platforms and select a user base (simply _All Users_ if you don't mind bothering all users).
    1. _Content_: Select _Push notification_ and click the _Add content_ button. Set a text (notification body) and check the optional _Title_ feature to provide a title.
    1. _Delivery_: Select _Send Now_ and enable _Mutable Content_ as well as _Badge_ (increment by +1). Also add the following _Custom Keys_ that describe the content associated with the push notification:
        - `media`: The URN of the media you picked.
        - `show`: The URN of the show you picked and subscribed to.
        - `type`: Set to `newod` (new on-demand).
        - `imageUrl`: The URL of the image to be displayed in the notification (without scaling path components; use the URL as returned by the IL).

        Other fields can be optionally filled if desired:
    
        - `channelId`: The id of the radio channel which the show belongs to (if none simply omit this field).
        - `startTime`: The time at which to start playback, in seconds. Omit this field to start at the default position.

    1. _Review & Send_: Click on _Send Message_ and observe your test device. Using debug builds you can also set breakpoints and inspect the app or extension code as needed.

#### Remark

To check that your setup is working you can initially create very a basic push notification containing a simple body, omitting all other fields. This notification will be processed by the app but will not provide any action or image.
