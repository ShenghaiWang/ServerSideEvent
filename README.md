# ServerSideEvent

A very light way Server Side Event library and the data is published via Combine publisher.

## Install

    .package(url: "git@github.com:ShenghaiWang/ServerSideEvent.git", from: "1.0.0")

## Usage

    _ = EventSource(request: endpoint.urlRequest)
        .eventPublisher
        .sink { event in
            // handle event here
        }
