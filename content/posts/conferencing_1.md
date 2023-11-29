---
title: "Starting a new conference"
author: "Rick Rackow"
date: 2023-11-28T10:35:50+01:00
subtitle: "because what could possibly go wrong?!"
image: ""
draft: false
tags: ["Conference","SkySummit","Cloud"]
---

A while ago, there as a little bit of a [conversation](https://twitter.com/RiRa12621/status/1565673036858232835) happening on Twitter, that
was sparked by [Matthias's](https://twitter.com/MetalMatze) [statement](https://x.com/MetalMatze/status/1560286593621131265?s=20) that more 
and more meetups are happening again. Now only a short year later, I felt like it was time.
The time to actually follow through and start a new conference. In case you haven't seen it yet: 

[SkySummit](https://skysummit.io)

This is a new thing. I mean, sure, I've organised a handful of concerts when I was in
my early 20s, but I'm not sure that's comparable. So I thought, I'd share my
learnings here in a blog post, or rather series of them, since the whole thing is
still ongoing. I want to somehow share the experience but also maybe help
others to know what they'll need to get their own conference started.

## Naming

Honestly, my biggest focus here was just to not get into copyright infringement issues.
Makes it also easier to get higher rankings on Google as if you were to compete
with 50 other things for the same company.

**Cost: 0EUR**

## Domain

Next up I had to get the domain [skysummit.io](https://skysummit.io) cost me 36$
with Cloudflare. Simplicity is key here for me as well and the other advantage,
besides the cost, is that I would be able to also host a static page later on.

There are a bunch of other options, obviously. Previously I used to default to
Google Domains, but since they sold off that bit to square, I really default to
Cloudflare now. The downside is, that they don't offer that wide of a variety of
TLDs. In this case, I would have otherwise opted for a `.berlin` one, but so be it.

**Cost: 36$**
**Total Cost This Far: 35EUR**

## Incorporation

I cannot state this highly enough: form _some_ sort of corporate entity that you
will use to handle everything related to your conference. Separation of finances
is one of the biggest aspects here and that just gets a lot easier if you separate
everything. Every invoice I get, every bill I pay or receipt I send out is now in the
name of the corporation and the money goes to or gets taken from a separate bank account.
I can therefore seamlessly form a papertrail for all my actions and make sure I can
provide that when it comes down to taxes but also prove that I'm not commiting any
kind of fraud. Additionally, I now have the option to have proper working contracts
in case I need to pay any personell later.

**THIS IS NOT LEGAL ADVICE**

I personally went with a German corporation. Mainly because the conference is
supposed to take place in Germany and therefore getting contracts and everything
established between German entities is pretty straight forward. Additionally, my
wife has a background in finance and is pretty familiar with German laws around that
whole topic, as opposed to e.g. a C-Corp or an LLC in the US.

When in Germany, things get complicated. There are a bunch of different options
and they all have their pros and cons. If you want to be on the safe side as much
as possible when it comes to liability separation between you and your business
a "GmbH" is your best option. It's basically a limited liability company. The downside
is that you need to put 25k subscribed capital in. That does not actually have to be
cash in the bank. You could also have a different static asset worth that. I didn't actually
want not put an asset down and then the options shrink a little. You could do an
"UG" but then you basically build up the 25k in asset over time and then reform to
a "GmbH". The next best option would be a "GbR" but that requires two people (at least)
to form. So I'm left with "Einzelunternehmer", wich I went with.

Creating the corporation is decently easy: sign the papers online and wait. The more problematic
part comes after that: taxes. In order to get a tax number (which I really wanted),
you need to fill a 15-page-long survey on the [Elster](https://www.elster.de/eportal/start)
website. Honestly, I just filled it to the best of my knowledge and now I'm waiting.


At some point you'll get back your "Gewerbeschein" so your confirmation that you
have formed the given legal entity and are the owner.

**Cost: 15EUR**
**Total Cost This Far: 50EUR**

## Banking

I went with [Qonto](https://qonto.com/r/oonxa9). I wanted to have as low as possible
monthly cost and that's it. I'm not expecting a high outbound transaction volume
and receiving money is free pretty much everywhere. I am such a big fan of Mercury,
but sadly, they're not available in  Europe yet, so I chose something that promised
an equally easy signup process and clean dashboard. So far I'm pretty happy.
I had to sign on, verify my identity online in a quick call, send over my "Gewerbeschein"
and now I am the happy owner of a bank account, including a credit card. The whole thing costs like 20EUR per month.
There's no signup, but I chose to top up my account with 100EUR so there's something
to get started with. Let's just calculate that as cost.


**Cost: 100EUR**
**Total Cost This Far: 150EUR**


## Website
Next up we need a website. I have a lot of things to do, so friggling with
design and what not wasn't really high up on my list. Hence, I decided to try one
of the nocode tools. [TeleportHQ](https://play.teleporthq.io/) looked promising
and honestly, I have no complains. It's free, and you get the option to use "AI".
No idea what they're using under hood and honestly, I don't actually care. So, I
went through the process and got a half decent website out. Some customisations here
and there, that you can actually do in a drag & drop manner, and then I was done.

The cool thing is, that you can either host on their service or download the source
code. I did that and customized a little bit in a local IDE (Jetbrains WebStrom, in case your wondering)
and then pushed the whole thing to a repo. Now is the time for Cloudflare again:

You go to the front page, then choose _Workers and Pages_ and create a new application.
You can hook that directly to a GitHub repo. After you're done, you can choose a custom
domain, ideally one that you have the records for on Cloudflare. Done.
The whole deploy, hosting, DNS blah took less than 5 minutes. Absolutely stellar.
And now any change I make, like adding new speakers or other things, gets deployed
automatically on a push to the main branch. The whole things is free. Perfect.


**Cost: 0EUR**
**Total Cost This Far: 150EUR**


## Location
Since this is the first time, the whole thing is guess work, and if I fuck it up,
I have a lot of explaining to do to my wife. That makes finding a location really,
really hard. Essentially I just looked at other "not super big" conferences and
their attendance number and then eyeballed the whole thing. Why would I do that?
Well, the issue is, if I start with ticket sales, a) I can't actually tell people
where they'll see the conference, but much worse b) I have to wait. When it comes
to locations and event venues, time is everything. The more time between now and the
day of the event, the better your chances to get a good venue.
After finishing my guessing, I figured that roughly 500 people should be doable.
That means 125 per track, so 125 per interest group. Now I went off to find a location.
There were basically two that I liked: [Malzfabrik](https://malzfabrik.de/) & [Motorwerk](https://www.motorwerk.de/).
I asked both of them for a quote for renting the venue for the specified dates and
after some back and forth it turned out that Malzfabrik couldn't rent out the whole place
and the sections they had wouldn't fit everyone in a room for e.g. Keynotes while also
offering a place for lunch and coffee. So Motorwerk was in. They were super nice, and
it seems they've done events like that in the past. We'll see how it turns out in the end
and if people will like it. Now comes the fun part: the price.

The cost basically is split up into a bunch of different things, that are mandatory mostly
but some are just recommended, like for example the chairs. Like, why would I rent chairs
for 1EUR less per chair somewhere else but then have to ship them to the location
and pay people to unload them and what not.

Let's take a look at some of the cost factors:
* Rent per day: 9900EUR (We need 2 days for the event and 0,5 for build up)
* Rent for catering room for 3 days: 3000EUR
* Cost of running (power and water): 4500EUR
* Lights (base pack, can't opt out because it's fixed installed): 9000EUR
* Sound (same as above): 4500

There's  bunch more, but the total in the estimate is slightly north of 70k.

I won't lie, the number caught me a bit off guard, but I check with some friends
with a little more experience, and it seems fair. Not cheap, but fair.

Now the way it works is, that I sign, pay 50% and then the rest later.

**Cost: 72471EUR**
**Total Cost This Far: 72621**

_That escalated quickly_

There are some other cost here that aren't really included yet but definitely have to
come on top like security, that this specific location requires to be arranged with them.
In other cases, you might be able to bring your own team (that still has be licensed so
can't just bring a couple of friends and be good). Security comes at around 35EUR
per hour and this venue requires approx 10 people to cover entry and all the exits because
emergency doors can't be locked, so you need a sec person there. Then an additional
person for the night and one that's called "Brandwache". So that will be around
10k again.

## Catering
If you come to conference, and you pay XY amount you deserve food. Period. Lucky me,
my best friend used to own a restaurant, is a chef and now works as head chef for
some fancy spa. That means for me, I get good deals from reasonable catering firms.
If you do this, you have to ask yourself what you want to offer. For me, I get very
hangry very easily, so I basically need some options all day. The idea is to have
coffee with some light snacks and fruit between doors opening and the first keynote,
then lunch in the lunch break and some snacks and cake and coffee in the afternoon in
a smaller break. The whole thing comes to around 70EUR per person per day, so 500
expected attendees + round about 50 speakers + staff and the whole shebang for two days.
So round about 80000EUR. That is **without** any drinks. We're still figuring out
how much that's going to be and what we actually need, but assume somewhere around the
20EUR per person per day mark so round about 25k.

The cost aside it is important to offer something for everyone, hence there's a field
in the ticket form to ask for food preferences: vegan, vegetarian or if you eat everything.

The good thing is, that this doesn't really have to be paid out of pocket. Basically,
when someone buys a ticket, I know that I have to order ticket for one person extra and
by that time, I collected their money.

What else does a good conference need? A social event. Basically for that I'm planning
mostly drink and some basic fingerfood, so we're probably looking at another 20EUR
per person. So we're at about 10k for that.

We also need a speaker dinner. Can't say too much about that though. It's supposed
to be a little bit of a surprise, but can calculate around 50EUR per person * 50 speakers
brings us to another 2500EUR.


One thing we do have here is time. There's no rush to get this done as soon as possible
especially since I have the contacts already for caterers but also delivery companies
for drinks and stuff. I can basically just ping them like a month in advance, when most
ticket sales should be through and I can make an assumption and give them the go.
A not so cool bit, that I'm still trying to regulate is, that there's no tasting option.
I really don't like to buy meals blindly. I wouldn't go to a restaurant either, ask for the price
and then hope for the best and eat what I get. Sure there are things like tasting menus, but
we're not really shooting for Michelin Star cuisine. 

**Costs: 117500EUR**
**Total Cost This Far: ~190000EUR**


## Tickets
Tickets are an absolutely nasty but essential piece. Why nasty? Because of the money.
If you are organising a conference, and you're not associated with a foundation or
a company that's paying the checks you desperately need the money. I mean we're at
190k this far. That money has to somehow come from somewhere.

The issue with most ticket providers is that they pay you **after** the event.
Somewhere between a couple of days and two weeks is pretty average. That means
I'd basically have to cover the total cost out of pocket and I don't know about you,
but I currently don't have 190k in the bank not knowing what to do with them. So, I
needed an alternative to the usual suspects like Eventbrite and landed at [Ticket Tailor](https://get.tickettailor.com/innkcx948lv2).
The whole sign up process is pretty easy: you create what they call a "box office" and then your "box office"
sells tickets to different events. In this case, one event, SkySummit. They rely on Stripe
for the actual payments, so no money ever touches their bank account. Everything goes right
through to Stripe, and then you can choose how often you want payouts from Stripe. I'll not
largely talk about Stripe. They're well known and their whole process is pretty easy.

The cost here works per ticket. Since I chose "pay as you go" it's 60 Cents per ticket plus VAT,
so that comes down to 71 Cents per ticket and then additionally Stripe charges you per
payment depending on what card you use to pay and from where and so on. But roughly 1,9% + 0,25EUR,
so in our case 990*0,019 = 18,81EUR plus the 0,25EUR, so close to 19,06 and then add the Ticket Tailor
fees, and it's 19,77EUR total per ticket, so roughly 10k if we sell out.

What I liked here, is that I don't really have to build a lot of stuff. You get a checkout page
that you just link to from your homepage and that's it. No wrangling of the styles and what not.

**Cost: 10000**
**Total Cost This Far: ~200000EUR**


## Call For Papers and Scheduling
A couple of different options here, but I chose [Sessionize](sessionize.com). It's pretty
cool to use: you sign up and fill in the details for your event. There are some default field for
the CFP (they actually call it CFS) but you can also define your own. In my case,
I added choices for which track a given talk should go on and the format: lightning, session or keynote.

You then define the timeframe until which CFP is going. From the CFPs that you get, you
get a breakdown by category and track (so really the fields you defined) and then you can move
a session between different statuses until they're accepted. You can also choose to bring in additional
people as reviewers and build like a content team, which is nice if you want to eliminate bias. 

If you want to be on the content team hit me up. Condition is that you haven't submitted a talk yourself though.

The cool part comes after the CFP is done though: from the sessions that you accepted you get to build
a schedule for your event. And that works nicely with drag and drop, and you keep a good
view of your event in total. CFP isn't over for me, but so far it looks really promising.
Additionally, you can embed the schedule once it's published and even get a mobile app.

There's further testing to be done here. And I'll report further as things move along.

## Speakers & Sponsors
Technically, I wanted to talk about speakers and sponsors, but I'll let the whole drama with the
fake speaker profiles settle for a bit. (Yeah, really some idiot generated fake profiles to attract
top level speakers and sponsors).


# Closing Remarks

So far we've accumulated 200k in cost, have earned 0. I'd say it's going great.

I'll add another post, once we're a little further along, but so far, if you have questions
ping me on Twitter or LinkedIn or per mail.

If you want to support the whole effort, submit a talk [here](https://sessionize.com/skysummit/) 
or get your tickets [here](https://www.tickettailor.com/events/skysummitgbr/1073918). There's an early bird discount going.
