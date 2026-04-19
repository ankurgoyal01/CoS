---
service: "webbus"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Webbus acts purely as a message publisher. It does not consume any events from the Message Bus. All messages arrive at Webbus via synchronous HTTP POST from Salesforce; Webbus then publishes each validated message to the appropriate JMS topic on the internal Message Bus using a STOMP connection. The full list of permitted topics is statically whitelisted in `config/messagebus.yml`.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.topic.salesforce.webbus.create` | Webbus generic create | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.planning_object.create` | Planning object created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.planning_object.update` | Planning object updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.planning_object.delete` | Planning object deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.account.create` | Account created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.account.update` | Account updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.account.delete` | Account deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.opportunity.create` | Opportunity created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.opportunity.update` | Opportunity updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.opportunity.delete` | Opportunity deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.opportunity.sure_thing` | Opportunity sure-thing | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.opportunity.detailed_update` | Opportunity detailed update | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.opportunity.all_stagename_update` | Opportunity stage-name update | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.option.create` | Option created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.option.delete` | Option deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.option.update` | Option updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.option.detailed_update` | Option detailed update | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.option.createPostLive` | Option created post-live | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.case.create` | Case created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.case.update` | Case updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.case.delete` | Case deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.caseevent.create` | Case event created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.contact.create` | Contact created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.contact.update` | Contact updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.contact.delete` | Contact deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.division.create` | Division created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.division.update` | Division updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.division.delete` | Division deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.echosign.create` | Echosign document created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.echosign.update` | Echosign document updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.echosign.delete` | Echosign document deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.event.create` | Event created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.event.update` | Event updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.event.delete` | Event deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.merchantaddress.create` | Merchant address created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.merchantaddress.update` | Merchant address updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.merchantaddress.delete` | Merchant address deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.address__c.insert` | Address custom object inserted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.address__c.update` | Address custom object updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.address.delete` | Address deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.quantumlead.create` | Quantum lead created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.quantumlead.update` | Quantum lead updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.quantumlead.delete` | Quantum lead deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.salesgoal.create` | Sales goal created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.salesgoal.update` | Sales goal updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.salesgoal.delete` | Sales goal deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.socialliving.create` | Social living record created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.socialliving.update` | Social living record updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.socialliving.delete` | Social living record deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.task.create` | Task created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.task.update` | Task updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.task.delete` | Task deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.user.create` | User created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.user.update` | User updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.user.delete` | User deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.persona.create` | Persona created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.persona.delete` | Persona deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.lead.delete` | Lead deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.selected_taxonomy.create` | Selected taxonomy created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.selected_taxonomy.delete` | Selected taxonomy deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.pos_order.delete` | POS order deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.product_detail.create` | Product detail created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.product_detail.update` | Product detail updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.tag.delete` | Tag deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.informationrequest.create` | Information request created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.informationrequest.update` | Information request updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.forecast.delete` | Forecast deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.price.create` | Price created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.price.update` | Price updated | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.price.delete` | Price deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.mcnotifications.create` | MC notification created | Salesforce POST | `topic`, `body` |
| `jms.topic.salesforce.survey.delete` | Survey deleted | Salesforce POST | `topic`, `body` |
| `jms.topic.webbus.test` | Test message | Salesforce POST / manual testing | `topic`, `body` |

### Bulk Publish Detail

- **Topics**: All topics listed in `config/messagebus.yml` under the `message_bus_destinations` alias.
- **Trigger**: Synchronous HTTP POST to `POST /v2/messages/` from Salesforce.
- **Payload**: Each message carries a `topic` string (the destination JMS topic) and a `body` string (the serialised CRM payload). Body may be a plain string or a JSON-serialisable hash.
- **Consumers**: Internal Groupon services subscribing to the respective `jms.topic.salesforce.*` topics.
- **Guarantees**: At-least-once — any messages that fail to publish are returned to Salesforce for redelivery.

## Consumed Events

> No evidence found in codebase. Webbus does not consume any events from the Message Bus.

## Dead Letter Queues

> No evidence found in codebase. Failed messages are returned synchronously to Salesforce for redelivery rather than routed to a DLQ.
