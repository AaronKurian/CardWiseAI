const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const { env } = require('../config/env');
const { User } = require('../models/User');
const { httpError } = require('../utils/httpError');

const toUserResponse = (user) => ({
  id: user._id,
  email: user.email,
  profile: user.profile,
});

const signToken = (user) =>
  jwt.sign({ sub: user._id.toString(), email: user.email }, env.jwtSecret, {
    expiresIn: env.jwtExpiresIn,
  });

const register = async ({ email, password, name }) => {
  if (!email || !password) {
    throw httpError(400, 'Email and password are required');
  }

  const existingUser = await User.findOne({ email: email.toLowerCase().trim() });
  if (existingUser) {
    throw httpError(409, 'Email is already registered');
  }

  const passwordHash = await bcrypt.hash(password, 12);
  const user = await User.create({
    email,
    passwordHash,
    profile: { name: name || '' },
  });

  return { user: toUserResponse(user), token: signToken(user) };
};

const login = async ({ email, password }) => {
  if (!email || !password) {
    throw httpError(400, 'Email and password are required');
  }

  const user = await User.findOne({ email: email.toLowerCase().trim() });
  if (!user) {
    throw httpError(401, 'Invalid email or password');
  }

  const validPassword = await bcrypt.compare(password, user.passwordHash);
  if (!validPassword) {
    throw httpError(401, 'Invalid email or password');
  }

  return { user: toUserResponse(user), token: signToken(user) };
};

module.exports = { register, login, toUserResponse };
