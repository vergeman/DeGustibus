DeGustibus is a final project by Alan Verga (akv2001) for CS6998
Search Engine Technology, Columbia University, Prof. Radev.

Tired of eating the same old thing?  Degustibus is a web-based (LAMP)
"lunch engine" designed to give novel and relevant food suggestions
from restaurants in the Columbia University area.  Employing K-means
clustering and relevance feedback, Degustibus rotates around clusters
to maximize the novelty of suggestions and the diversity of results.
Selections are used to refine browsing and discover similar offerings
in the neighborhood.

Several dependencies / plugins are required.

Back-end
CPAN/Clairlib Perl Modules

* URI::URL
* WWW::Curl::Easy
* DBI
* HTML::Entities
* HTML::Strip
* XML::Simple
* XML::Parser::PerlSAX
* Clair::Utils::Stem

C++ / PHP
* Apache Thrift, http://incubator.apache.org/thrift/download/
* Boost 1.46.1 C++ Library, http://www.boost.org/

Front-end
* Google Maps API
* jQuery, http://www.jquery.com
