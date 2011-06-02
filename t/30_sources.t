use strict;
use warnings;

use lib 't';
use TestPlackApp;

use Test::More;
use Plack::Test;
use Plack::Builder;
use RDF::Light;
use RDF::Light::Source;
use RDF::Trine::Model;
use RDF::Trine qw(iri statement);

my $not_found = sub { [404,['Content-Type'=>'text/plain'],['Not found']] };

my $example_model = RDF::Trine::Model->temporary_model;
$example_model->add_statement(statement( 
    map { iri("http://example.com/$_") } qw(subject predicate object) ));

test_app
    name => "RDF::Trine::Model as source",
    app => builder {
        enable "+RDF::Light", 
            base => "http://example.com/", 
            source => $example_model;
        $not_found;
    },
    tests => [{
        request => [ 'GET', '/subject', [ 'Accept' => 'text/turtle' ] ],
        content => qr{subject>.+predicate>.+object>},
        code    => 200,
    },{
        request => [ 'GET', '/adverb', [ 'Accept' => 'text/turtle' ] ],
        content => 'Not found',
        code    => 404,
    }];
 
test_app
    name => "Array of sources",
    app => builder {
        enable "+RDF::Light", 
            base => "http://example.com/", 
            source => [ $example_model, \&dummy_source ];
        $not_found;
    },
    tests => [{
        request => [ 'GET', '/subject', [ 'Accept' => 'text/turtle' ] ],
        content => qr{subject>.+predicate>.+object>},
        code    => 200,
    },{
        request => [ 'GET', '/adverb', [ 'Accept' => 'text/turtle' ] ],
        content => qr{adverb> a.+Resource>},
        code    => 200,
    }];

done_testing;
