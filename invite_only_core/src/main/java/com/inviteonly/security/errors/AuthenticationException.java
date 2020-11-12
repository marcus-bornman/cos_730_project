package com.inviteonly.security.errors;

public class AuthenticationException extends org.springframework.security.core.AuthenticationException {
	public AuthenticationException(String msg, Throwable t) {
		super(msg, t);
	}

	public AuthenticationException(String msg) {
		super(msg);
	}
}
