package Voson::Plugin::SocketIO;
use 5.008005;
use strict;
use warnings;
use parent 'Voson::Plugin';
use PocketIO;
use Voson::Plugin::SocketIO::Assets;

our $VERSION = "0.01";

sub new {
    my ($class, %opts) = @_;
    my $self = $class->SUPER::new(%opts);
    my $app = $self->app;
    $app->{socketio}{js_path}      ||= '/socket.io.js';
    $app->{socketio}{socket_path}  ||= '/socket.io';
    $app->action_chain->append(
        'SocketIO'           => $class->can('_socketio_init'),
        'SocketIO::Dispatch' => $class->can('_socketio_dispatch'),
    );
    $app->filter_chain->append(
        'SocketIO::Inject'   => $class->can('_socketio_inject'),
    );
    return $self;
}

sub exports {qw/socketio/};

sub socketio {
    my ($self, $context) = @_;
    sub ($&) {
        my ($event, $code) = @_;
        $self->app->{socketio}{event}{$event} = $code;
    };
}

sub _socketio_dispatch {
    my ($app, $context) = @_;
    my $reader = $app->{socketio}{data_section};
    my $req = $context->get('req');
    my $res = 
        $req->path eq $app->{socketio}{js_path}     ? [200, ['Content-type' => 'text/javascript'], [Voson::Plugin::SocketIO::Assets->get('socket.io.js')]] :
        $req->path eq $app->{socketio}{socket_path} ? $app->{socketio}{pocketio}->($req->env) :
        undef
    ;
    return ($context, $res);
}

sub _socketio_init {
    my ($app, $context) = @_;
    $app->{socketio}{pocketio} ||= PocketIO->new(handler => sub {
        my $socket = shift;
        for my $event (keys %{$app->{socketio}{events}}) {
            my $action = $app->{socketio}{events}{$event};
            $socket->on($event => $action);
        }
        $socket->send({buffer => []});
    });
    return $context;
}

sub _socketio_inject {
    my ($app, $content) = @_;
    my $js_path = $app->{socketio}{js_path};
    $content =~ s|(</body>)|$1\n<script type="text/javascript" src="$js_path"></script>|i;
    return $content;
}

1;

__END__

=encoding utf-8

=head1 NAME

Voson::Plugin::SocketIO - It's new $module

=head1 SYNOPSIS

    use Voson::Plugin::SocketIO;

=head1 DESCRIPTION

Voson::Plugin::SocketIO is ...

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

